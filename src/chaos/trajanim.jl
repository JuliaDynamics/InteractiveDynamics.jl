using DataStructures
export interactive_evolution, interactive_evolution_timeseries

# TODO: Allow plotted timeseries to be arbitrary functions of state
# and to be more or less than the state dimension.

# TODO: Perhaps competely remove the sleeping part of the stepping,
# and instead replace it with take "x" steps of the integrator...?
# So, do it like in the DynamicalBilliards.jl application?
# So for all steps before the last, the CircularBuffers are updated.
# In the last step the update is propagated in all observables.
# This would make much smoother animations.
# YES. DO THIS.

# TODO: Allow custom labels, by default x1, x2, x3.
# How to incorporate this with arbitrary timeseries?


"""
    interactive_evolution(ds::DynamicalSystem [, u0s]; kwargs...) → fig, obs
Launch an interactive GUI application that can evolve the initial conditions `u0s`
(vector of vectors) of the given dynamical system.
All initial conditions are evolved in parallel and at exactly the same time.
Two controls allow you to pause/resume the evolution and to adjust the speed.
The application can run forever (trajectories are computed on demand).

By default the GUI window displays statespace and timeseries plots.
It also allows changing the parameters of `ds` live during the
system evolution, see keyword `params` below in "Parameter Keywords".

The function returns `fig, obs`. `fig` is the overarching figure
(the entire GUI) and can be recorded with `Makie.record`.
`obs` is a vector of observables, each containing the current state of the trajectory.

The figure layout is as follows:
1. `fig[1,1]` = state space plot and evolution control
2. `fig[1,2]` = timeseries plots
3. `fig[2,:]` = parameter controls (if `ps` is given)

## State Space Keywords
* `transform = identity`: Transformation applied to the state of the dynamical system
  before plotting. Can even return a vector that is of higher dimension than `ds`.
* `idxs = 1:min(length(transform(u0s[1])), 3)`: Which variables to plot (up to three can be chosen).
  Variables are selected after `transform` has been applied.
* `colors`: The color for each trajectory. Random colors are chosen by default.
* `lims`: A tuple of tuples (min, max) for the axis limits. If not given, they are
  automatically deduced by evolving each of `u0s` 1000 units and picking most extreme
  values (limits cannot be adjusted after application is launched).
* `m = 1.0`: The trajectory endpoints have a marker. A heuristic is done to choose
  appropriate marker size given the trajectory size. `m` is a multiplier that scales
  the marker size.
* `tail = 1000`: Length of plotted trajectory (in step units of the integrator).
* `plotkwargs = NamedTuple()` : A named tuple of keyword arguments propagated to
  the state space plot (`lines` for continuous, `scatter` for discrete systems).
  `plotkwargs` can also be a vector of named tuples, in which case each initial condition
  gets different arguments.
* `diffeq = NamedTuple()`: Named tuple of keyword arguments propagated to
  the solvers of DifferentialEquations.jl (for continuous systems). Because trajectories
  are not pre-computed and interpolated, but rather calculated on the fly step by step,
  it is **strongly recommended** to use an ODE solver thas has a constant step size
  instead of being adaptive. For example `diffeq = (alg=Tsit5(), adaptive=false, dt=0.01)`.

## Timeseries Keywords
* `total_span`: How much the x-axis of the timeseries plots should span (in real time units)
* `linekwargs = NamedTuple()`: Extra keywords propagated to the timeseries plots.

## Parameter Keywords
* `ps = nothing`: If `ps` is not nothing, then it must be a dictionary, mapping keys
  of the system parameter container (`ds.p`) to possible ranges of values. The app then will
  add some additional controls on the bottom of the GUI which allow one to interactively change
  system parameters and then click the "update" button to translate the new parameters to
  system evolution. This can be done without stopping the live system evolution.
  Notice that in this scenario it is recommended to provide the `lims` keyword manually.
  An extra argument is returned in this case: a dictionary mapping parameter keys
  to _observables_ containing their current values. You can use this to generate additional
  plot elements that may depend on system parameters and thus need to be changed
  if the sliders are changed.
* `pnames = Dict(keys(ps) .=> keys(ps))` : Dictionary mapping parameter keys to labels.
  Only valid if `params` is a dictionary and not `nothing`.
"""
function interactive_evolution(
        ds::DynamicalSystems.DynamicalSystem, u0s = [ds.u0];
        transform = identity, idxs = 1:min(length(transform(ds.u0)), 3),
        colors = [CYCLIC_COLORS[i] for i in 1:length(u0s)], tail = 1000,
        diffeq = NamedTuple(),
        plotkwargs = NamedTuple(), m = 1.0,
        lims = traj_lim_estimator(ds, u0s, DynamicalSystems.SVector(idxs...), transform),
        total_span = ds isa DynamicalSystems.ContinuousDynamicalSystem ? 10 : 50,
        linekwargs = ds isa DynamicalSystems.ContinuousDynamicalSystem ? (linewidth = 4,) : (),
        ps = nothing,
        pnames = isnothing(ps) ? nothing : Dict(keys(ps) .=> keys(ps)),
    )

    N = length(u0s)
    @assert length(idxs) ≤ 3 "Only up to three variables can be plotted!"
    @assert length(colors) ≥ length(u0s) "You need to provide enough colors!"
    idxs = DynamicalSystems.SVector(idxs...)
    fig = Figure(resolution = (1600, 800), )

    pinteg = DynamicalSystems.parallel_integrator(ds, u0s; diffeq)

    statespacelayout = fig[1,1] = GridLayout()
    timeserieslayout = fig[1,2] = GridLayout()
    if !isnothing(ps)
        paramlayout = fig[2, :] = GridLayout(tellheight = true, tellwidth = false)
    end

    # Initialize statespace plot with correct dimensionality
    statespaceax, obs, finalpoints, run, sleslider = _init_statespace_plot!(
        statespacelayout, ds, idxs, lims, pinteg, colors, plotkwargs, m, tail, transform,
    )

    allts, ts_axes = _init_timeseries_plots!(
        timeserieslayout, pinteg, idxs, colors, linekwargs, transform, tail, lims,
    )

    # Functionality of live evolution. This links all observables with triggers.
    isrunning = Observable(false)
    on(run) do clicks; isrunning[] = !isrunning[]; end
    on(run) do clicks
        @async while isrunning[]
        # while isrunning[]

        # TODO: Perhaps steppng of continuous time systems can be made a
        # smoother process....?
            DynamicalSystems.step!(pinteg)
            for i in 1:N
                ob = obs[i]
                last_state = transform(DynamicalSystems.get_state(pinteg, i))[idxs]
                pushupdate!(ob, last_state) # push and trigger update with `=`
                for k in 1:length(idxs)
                    pushupdate!(allts[k][i], Point2f(pinteg.t, last_state[k]))
                end
            end
            finalpoints[] = [x[][end] for x in obs]
            sleslider[] == 0 ? yield() : sleep(sleslider[])
            t_current = pinteg.t
            xlims!(ts_axes[end], max(0, t_current - total_span), max(t_current, total_span))
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window
        end
    end

    # Live parameter changing
    if !isnothing(ps)
        slidervals, returnvals = _add_ds_param_controls!(paramlayout, ps, copy(ds.p), pnames)
        update = Button(fig, label = "update", tellwidth = false)
        paramlayout[length(ps)+1, :] = update
        on(update.clicks) do clicks
            _update_ds_parameters!(ds, slidervals, returnvals)
        end
    else
        returnvals = nothing
    end

    display(fig)
    return fig, obs, returnvals
end




"Create the state space axis and evolution controls. Return the axis."
function _init_statespace_plot!(
        layout, ds, idxs, lims, pinteg, colors, plotkwargs, m, tail, transform,
    )
    obs, finalpoints = init_trajectory_observables(pinteg, tail, idxs, transform)
    is3D = length(idxs) == 3
    mm = maximum(abs(x[2] - x[1]) for x in lims)
    ms = m*(is3D ? 4000 : 15)
    statespaceax = is3D ? Axis3(layout[1,1]) : Axis(layout[1,1])

    # Initialize trajectories plotted element
    for (i, ob) in enumerate(obs)
        pk = plotkwargs isa Vector ? plotkwargs[i] : plotkwargs
        if !DynamicalSystems.isdiscretetime(ds)
            Makie.lines!(statespaceax, ob;
                color = colors[i], linewidth = 2.0, pk...
            )
        else
            Makie.scatter!(statespaceax, ob; color = colors[i],
                markersize = 2ms/3, strokewidth = 0.0, pk...
            )
        end
    end
    finalargs = if !DynamicalSystems.isdiscretetime(ds)
        (marker = :circle, )
    else
        (marker = :diamond, )
    end
    Makie.scatter!(statespaceax, finalpoints; color = colors, markersize = ms, finalargs...)
    !isnothing(lims) && (statespaceax.limits = lims)
    is3D && (statespaceax.protrusions = 50) # removes overlap of labels

    run, sleslider = trajectory_plot_controls!(layout)
    return statespaceax, obs, finalpoints, run, sleslider
end
function init_trajectory_observables(pinteg, tail, idxs, transform)
    N = length(DynamicalSystems.get_states(pinteg))
    obs = Observable[]
    T = length(idxs) == 2 ? Point2f : Point3f
    for i in 1:N
        cb = CircularBuffer{T}(tail)
        fill!(cb, T(transform(DynamicalSystems.get_state(pinteg, i))[idxs]))
        push!(obs, Observable(cb))
    end
    finalpoints = Observable([x[][end] for x in obs])
    return obs, finalpoints
end
function trajectory_plot_controls!(layout)
    layout[2, 1] = controllayout = GridLayout(tellwidth = false)
    run = Button(controllayout[1, 1]; label = "run")
    _s, _v = 10.0 .^ (-5:0.1:0), 0.1
    pushfirst!(_s, 0.0)
    slesl = labelslider!(layout.parent.parent, "sleep =", _s;
    sliderkw = Dict(:startvalue => _v), valuekw = Dict(:width => 100),
    format = x -> "$(round(x; digits = 5))")
    controllayout[1, 2] = slesl.layout
    return run.clicks, slesl.slider.value
end



function _init_timeseries_plots!(
        layout, pinteg, idxs, colors, linekwargs, transform, tail, lims
    )
    N = length(DynamicalSystems.get_states(pinteg))
    # Initialize timeseries data:
    allts = [] # each entry is one timeseries plot, which contains N series
    for i in 1:length(idxs)
        individual_ts = Observable[]
        for j in 1:N
            cb = CircularBuffer{Point2f}(tail)
            fill!(cb, Point2f(
                pinteg.t, transform(DynamicalSystems.get_state(pinteg, j))[idxs][i])
            )
            push!(individual_ts, Observable(cb))
        end
        push!(allts, individual_ts)
    end
    # Initialize timeseries axis and plots:
    ts_axes = []
    for i in 1:length(idxs)
        ax = Axis(layout[i, 1]; xticks = LinearTicks(5))
        push!(ts_axes, ax)
        individual_ts = allts[i]
        for j in 1:N
            lines!(ax, individual_ts[j]; color = colors[j], linekwargs...)
            if DynamicalSystems.isdiscretetime(pinteg)
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
    return allts, ts_axes
end

function traj_lim_estimator(ds, u0s, idxs, transform)
    _tr = DynamicalSystems.trajectory(ds, 2000.0, u0s[1]; Δt = 1)
    tr = DynamicalSystems.Dataset(transform.(_tr.data))
    _mi, _ma = DynamicalSystems.minmaxima(tr)
    mi, ma = _mi[idxs], _ma[idxs]
    for i in 2:length(u0s)
        _tr = DynamicalSystems.trajectory(ds, 2000.0, u0s[i]; Δt = 1)
        tr = DynamicalSystems.Dataset(transform.(_tr.data))
        _mii, _maa = DynamicalSystems.minmaxima(tr)
        mii, maa = _mii[idxs], _maa[idxs]
        mi = min.(mii, mi)
        ma = max.(maa, ma)
    end
    # Alright, now we just have to put them into limits and increase a bit
    mi = mi .- 0.1mi
    ma = ma .+ 0.1ma
    lims = [(mi[i], ma[i]) for i in 1:length(idxs)]
    lims = (lims...,)
end




function _add_ds_param_controls!(paramlayout, ps, p0, pnames)
    fig = paramlayout.parent.parent
    slidervals = Dict{keytype(ps), Observable}()
    returnvals = Dict{keytype(ps), Observable}()
    for (i, (l, vals)) in enumerate(ps)
        startvalue = p0[l]
        label = string(pnames[l])
        sll = labelslider!(fig, label, vals; sliderkw = Dict(:startvalue => startvalue))
        slidervals[l] = sll.slider.value # directly add the observable
        returnvals[l] = Observable(sll.slider.value[]) # will only get updated on button
        paramlayout[i, :] = sll.layout
    end
    return slidervals, returnvals
end

function _update_ds_parameters!(ds, slidervals, returnvals)
    for l in keys(slidervals)
        v = slidervals[l][]
        returnvals[l][] = v
        DynamicalSystems.set_parameter!(ds, l, v)
    end
end








###############################################
# DEPRECATED
###############################################
function interactive_evolution_timeseries(ds, u0s, ps = nothing, kwargs...)
    @warn """
    Function `interactive_evolution_timeseries` is merged with `interactive_evolution`.
    Use that name instead from now on. Also, `ps` has now become a keyword.
    """
    return interactive_evolution(ds, u0s; ps, kwargs...)
end
