using DataStructures
export interactive_evolution, interactive_evolution_timeseries

"""
    interactive_evolution(ds::DynamicalSystem, u0s; kwargs...)
Launch an interactive application that can evolve the initial conditions `u0s`
(vector of vectors) of the given dynamical system.
All initial conditions are evolved in parallel and at exactly the same time.
Two controls allow you to pause/resume the evolution and to adjust the speed.
The application can run forever (trajectories are computed on demand).

The function returns `fig, obs`. `fig` is the overarching fig
(the entire GUI) and can be recorded.
`obs` is a vector of observables, each containing the current state of the trajectory.

## Keywords
* `transform = identity` : Transformation applied to the state of the dynamical system
  before plotting. Can even return a vector that is of higher dimension than `ds`.
* `idxs = 1:min(length(transform(ds.u0)), 3)` : Which variables to plot (up to three can be chosen).
  Variables are selected after `transform` has been applied.
* `colors` : The color for each trajectory. Random colors are chosen by default.
* `lims` : A tuple of tuples (min, max) for the axis limits. If not given, they are
  automatically deduced by evolving each of `u0s` 1000 units and picking most extreme
  values (limits cannot be adjust after application is launched).
* `m = 1.0` : The trajectory endpoints have a marker. A heuristic is done to choose
  appropriate marker size given the trajectory size. `m` is a multiplier that scales
  the marker size.
* `plotkwargs = NamedTuple()` : A named tuple of keyword arguments propagated to
  the plotting function (`lines` for continuous, `scatter` for discrete systems).
  `plotkwargs` can also be a vector of named tuples, in which case each initial condition
  gets different arguments.
* `tail = 1000` : Length of plotted trajectory (in step units).
* `diffeq = NamedTuple()` : Named tuple of keyword arguments propagated to
  the solvers of DifferentialEquations.jl (for continuous systems). Because trajectories
  are not pre-computed and interpolated, it is recommended to use a combination of
  arguments that limit maximum stepsize, to ensure smooth curves. For example:
  ```julia
  using OrdinaryDiffEq
  diffeq = (alg = Tsit5(), dtmax = 0.01)
  ```
"""
function interactive_evolution(
        ds::DynamicalSystems.DynamicalSystem{IIP}, u0s;
        transform = identity, idxs = 1:min(length(transform(ds.u0)), 3),
        colors = [CYCLIC_COLORS[i] for i in 1:length(u0s)],
        tail = 1000, diffeq = NamedTuple(),
        plotkwargs = NamedTuple(), m = 1.0,
        lims = traj_lim_estimator(ds, u0s, diffeq, DynamicalSystems.SVector(idxs...), transform),
    ) where {IIP}

    @assert length(idxs) ≤ 3 "Only up to three variables can be plotted!"
    @assert length(colors) ≥ length(u0s) "You need to provide enough colors!"
    idxs = DynamicalSystems.SVector(idxs...)
    fig = Figure(resolution = (1000, 800), )
    pinteg = DynamicalSystems.parallel_integrator(ds, u0s; diffeq)
    obs, finalpoints = init_trajectory_observables(length(u0s), pinteg, tail, idxs, transform)

    # Initialize main plot with correct dimensionality
    main = fig[1,1] = init_main_trajectory_plot(
        ds, fig, idxs, lims, pinteg, colors, obs, plotkwargs, finalpoints, m
    )

    # here we define the main updating functionality
    run, sleslider = trajectory_plot_controls(fig)

    isrunning = Observable(false)
    on(run) do clicks; isrunning[] = !isrunning[]; end
    on(run) do clicks
        @async while isrunning[]
        # while isrunning[]
            DynamicalSystems.step!(pinteg)
            for i in 1:length(u0s)
                ob = obs[i]
                # last_state = iipcds ? @view(pinteg.u[:, i])[idxs] : pinteg.u[i][idxs]
                last_state = transform(DynamicalSystems.get_state(pinteg, i))[idxs]
                ob[] = push!(ob[], last_state) # push and trigger update with `=`
            end
            finalpoints[] = [x[][end] for x in obs]
            sleslider[] == 0 ? yield() : sleep(sleslider[])
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window
        end
    end
    display(fig)
    fig, obs
end

function init_trajectory_observables(L, pinteg, tail, idxs, transform)
    obs = Observable[]
    T = length(idxs) == 2 ? Point2f0 : Point3f0
    for i in 1:L
        cb = CircularBuffer{T}(tail)
        fill!(cb, T(transform(DynamicalSystems.get_state(pinteg, i))[idxs]))
        push!(obs, Observable(cb))
    end
    finalpoints = Observable([x[][end] for x in obs])
    return obs, finalpoints
end

function init_main_trajectory_plot(
        ds, fig, idxs, lims, pinteg, colors, obs, plotkwargs, finalpoints, m
    )
    is3D = length(idxs) == 3
    mm = maximum(abs(x[2] - x[1]) for x in lims)
    ms = m*(is3D ? 4000 : 15)
    main = !is3D ? Axis(fig) : Axis3(fig)
    # Initialize trajectory plotted element
    for (i, ob) in enumerate(obs)
        pk = plotkwargs isa Vector ? plotkwargs[i] : plotkwargs
        if ds isa DynamicalSystems.ContinuousDynamicalSystem
            Makie.lines!(main, ob;
                color = colors[i], linewidth = 2.0, pk...
            )
        else
            Makie.scatter!(main, ob; color = colors[i],
                markersize = 2ms/3, strokewidth = 0.0, pk...
            )
        end
    end
    finalargs = if ds isa DynamicalSystems.ContinuousDynamicalSystem
        (marker = :circle, )
    else
        (marker = :diamond, )
    end
    Makie.scatter!(main, finalpoints;
        color = colors, markersize = ms, finalargs...
    )
    if !isnothing(lims)
        main.limits = lims
    end
    is3D && (main.protrusions = 50)
    return main
end
function trajectory_plot_controls(fig)
    fig[2, 1] = controllayout = GridLayout(tellwidth = false)
    run = controllayout[1, 1] = Button(fig; label = "run")
    _s, _v = 10.0 .^ (-5:0.1:0), 0.1
    pushfirst!(_s, 0.0)
    slesl = labelslider!(fig, "sleep =", _s;
    sliderkw = Dict(:startvalue => _v), valuekw = Dict(:width => 100),
    format = x -> "$(round(x; digits = 5))")
    controllayout[1, 2] = slesl.layout
    return run.clicks, slesl.slider.value
end


function traj_lim_estimator(ds, u0s, diffeq, idxs, transform)
    largedt_diffeq = merge(diffeq, (;dtmax = Inf))
    _tr = DynamicalSystems.trajectory(ds, 2000.0, u0s[1]; Δt = 1, diffeq = largedt_diffeq)
    tr = DynamicalSystems.Dataset(transform.(_tr.data))
    _mi, _ma = DynamicalSystems.minmaxima(tr)
    mi, ma = _mi[idxs], _ma[idxs]
    for i in 2:length(u0s)
        _tr = DynamicalSystems.trajectory(ds, 2000.0, u0s[i]; Δt = 1, diffeq = largedt_diffeq)
        tr = DynamicalSystems.Dataset(transform.(_tr.data))
        _mii, _maa = DynamicalSystems.minmaxima(tr)
        mii, maa = _mii[idxs], _maa[idxs]
        mi = min.(mii, mi)
        ma = max.(maa, ma)
    end
    # Alright, now we just have to put them into limits and increase by 10%
    mi = mi .- 0.05mi
    ma = ma .+ 0.05ma
    lims = [(mi[i], ma[i]) for i in 1:length(idxs)]
    lims = (lims...,)
end



"""
    interactive_evolution_timeseries(ds::DynamicalSystem, u0s, ps = nothing; kwargs...)
If `ps === nothing`, this function does the same as [`interactive_evolution`](@ref),
but in addition to the state space plot there is
a panel with the variable timeseries plotted and animated in real time.

If `ps` is not nothing, then it must be a dictionary, mapping keys
of the system parameter container (`ds.p`) to possible ranges of values. The app then will 
add some additional controls on the left side which allow one to interactively change
system parameters and then click the "update" button to translate the new parameters to
system evolution. This can be done without stopping the live system evolution.
Notice that in this scenario it is recommended to provide the `lims` keyword manually.

The following additional keywords also apply:
- `total_span` : How much the x-axis of the timeseries plots should span (in real time units)
- `linekwargs = NamedTuple()` : Extra keywords propagated to the timeseries plots.
- `pnames = Dict(keys(ps) .=> keys(ps))` : Dictionary mapping parameter keys to labels.
  Only valid if `ps` is a dictionary and not `nothing`.
"""
function interactive_evolution_timeseries(
        ds::DynamicalSystems.DynamicalSystem{IIP}, u0s, ps = nothing;
        transform = identity, idxs = 1:min(length(transform(ds.u0)), 3),
        colors = [CYCLIC_COLORS[i] for i in 1:length(u0s)],
        tail = 1000, diffeq = NamedTuple(),
        plotkwargs = NamedTuple(), m = 1.0,
        lims = traj_lim_estimator(ds, u0s, diffeq, DynamicalSystems.SVector(idxs...), transform),
        total_span = ds isa DynamicalSystems.ContinuousDynamicalSystem ? 10 : 50,
        linekwargs = ds isa DynamicalSystems.ContinuousDynamicalSystem ? (linewidth = 4,) : (),
        pnames = isnothing(ps) ? nothing : Dict(keys(ps) .=> keys(ps)),
    ) where {IIP}

    # TODO: Separate into traj_idxs and ts_idxs, in case one wants to plot
    # more timeseries than the ones in the state space plot

    N = length(u0s)
    @assert length(idxs) ≤ 3 "Only up to three variables can be plotted!"
    @assert length(colors) ≥ length(u0s) "You need to provide enough colors!"
    idxs = DynamicalSystems.SVector(idxs...)
    fig = Figure(resolution = (1600, 800), )
    pinteg = DynamicalSystems.parallel_integrator(ds, u0s; diffeq)
    obs, finalpoints = init_trajectory_observables(length(u0s), pinteg, tail, idxs, transform)
    tdt = total_span/50

    # Initialize main plot with correct dimensionality
    main = fig[1,1] = init_main_trajectory_plot(
        ds, fig, idxs, lims, pinteg, colors, obs, plotkwargs, finalpoints, m
    )

    # Initialize timeseries data:
    allts = [] # each entry is one timeseries plot, which contains N series
    for i in 1:length(idxs)
        individual_ts = Observable[]
        for j in 1:N
            cb = CircularBuffer{Point2f0}(tail)
            fill!(cb, Point2f0(
                pinteg.t, transform(DynamicalSystems.get_state(pinteg, j))[idxs][i])
            )
            push!(individual_ts, Observable(cb))
        end
        push!(allts, individual_ts)
    end

    # here we define the main updating functionality
    run, sleslider = trajectory_plot_controls(fig)

    # Initialize timeseries plots:
    ts_axes = []
    for i in 1:length(idxs)
        ax = fig[:, 2][i, 1] = Axis(fig; xticks = LinearTicks(5))
        push!(ts_axes, ax)
        individual_ts = allts[i]
        for j in 1:N
            lines!(ax, individual_ts[j]; color = colors[j], linekwargs...)
            if ds isa DynamicalSystems.DiscreteDynamicalSystem
                scatter!(ax, individual_ts[j]; color = colors[j])
            end
        end
        tight_xticklabel_spacing!(ax)
        ax.ylabel = string(('x':'z')[i])
        ylims!(ax, lims[i])
    end
    for i in 1:length(idxs)-1
        linkxaxes!(ts_axes[i], ts_axes[end]) 
        hidexdecorations!(ts_axes[i], grid = false)
    end
    xlims!(ts_axes[end], pinteg.t - tdt, total_span+tdt)

    # Functionality of live evolution
    isrunning = Observable(false)
    on(run) do clicks; isrunning[] = !isrunning[]; end
    on(run) do clicks
        @async while isrunning[]
        # while isrunning[]
            DynamicalSystems.step!(pinteg)
            for i in 1:N
                ob = obs[i]
                last_state = transform(DynamicalSystems.get_state(pinteg, i))[idxs]
                pushupdate!(ob, last_state) # push and trigger update with `=`
                for k in 1:length(idxs)
                    pushupdate!(allts[k][i], Point2f0(pinteg.t, last_state[k]))
                end
            end
            finalpoints[] = [x[][end] for x in obs]
            sleslider[] == 0 ? yield() : sleep(sleslider[])
            t_current = pinteg.t
            t_prev = max(0, t_current - total_span)
            xlims!(ts_axes[end], t_prev-tdt, max(t_current, total_span)+tdt)
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window
        end
    end

    # Live parameter changing
    if !isnothing(ps)
        playout = fig[:, 3] = GridLayout(tellheight = false)
        slidervals, returnvals = add_param_controls!(fig, playout, ps, copy(ds.p), pnames)
        update = Button(fig, label = "update", tellwidth = false)
        playout[length(ps)+1, :] = update
        on(update.clicks) do clicks
            update_ds_parameters!(ds, slidervals, returnvals)
        end
    else
        returnvals = nothing
    end

    display(fig)
    return fig, obs, returnvals
end

function add_param_controls!(fig, playout, ps, p0, pnames)
    slidervals = Dict{keytype(ps), Observable}()
    returnvals = Dict{keytype(ps), Observable}()
    for (i, (l, vals)) in enumerate(ps)
        startvalue = p0[l]
        label = string(pnames[l])
        sll = labelslider!(fig, label, vals; sliderkw = Dict(:startvalue => startvalue))
        slidervals[l] = sll.slider.value # directly add the observable
        returnvals[l] = Observable(sll.slider.value[]) # will only get updated on button
        playout[i, :] = sll.layout
    end
    return slidervals, returnvals
end

function update_ds_parameters!(ds, slidervals, returnvals)
    for l in keys(slidervals)
        v = slidervals[l][]
        returnvals[l][] = v
        DynamicalSystems.set_parameter!(ds, l, v)
    end
end
