using DataStructures
export interactive_evolution

"""
    interactive_evolution(ds::DynamicalSystem, u0s; kwargs...)
Launch an interactive application that can evolve the initial conditions `u0s`
(vector of vectors) of the given dynamical system.
All initial conditions are evolved in parallel and at exactly the same time.
Two controls allow you to pause/resume the evolution and to adjust the speed.
The application can run forever (trajectories are computed on demand).

The function returns `scene, main, layout, obs`. `scene` is the overarching scene
(the entire GUI) and can be recorded. `main` is the actual plot of the trajectory,
that allows adding additional plot elements or controlling labels, ticks, etc.
`layout` is the overarching layout, that can be used to add additional plot panels.
`obs` is a vector of observables, each containing the current state of the trajectory.

## Keywords
* `idxs = 1:min(dimension(ds), 3)` : Which variables to plot (up to three can be chosen).
* `colors` : The color for each trajectory. Random colors are chosen by default.
* `lims` : A tuple of tuples (min, max) for the axis limits. If not given, they are
  automatically deduced by evolving each of `u0s` 1000 units and picking most extreme
  values (limits cannot be adjust after application is launched).
* `plotkwargs = NamedTuple()` : A named tuple of keyword arguments propagated to
  the plotting function (`lines` for continuous, `scatter` for discrete systems).
* `tail = 1000` : Length of plotted trajectory (in step units).
* `diffeq = DynamicalSystems.CDS_KWARGS` : Named tuple of keyword arguments propagated to
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
        idxs = 1:min(DynamicalSystems.dimension(ds), 3),
        colors = [randomcolor() for i in 1:length(u0s)],
        tail = 1000, diffeq = DynamicalSystems.CDS_KWARGS,
        lims = traj_lim_estimator(ds, u0s, diffeq, DynamicalSystems.SVector(idxs...)),
        plotkwargs = NamedTuple(),
    ) where {IIP}

    @assert length(idxs) ≤ 3 "Only up to three variables can be plotted!"
    isnothing(lims) && @warn "It is strongly recommended to give the `lims` keyword!"
    @assert length(colors) ≥ length(u0s) "You need to provide enough colors!"
    idxs = DynamicalSystems.SVector(idxs...)
    scene, layout = layoutscene(resolution = (1000, 800), )
    pinteg = DynamicalSystems.parallel_integrator(ds, u0s; diffeq...)
    obs = init_trajectory_observables(length(u0s), pinteg, tail, idxs)

    # Initialize main plot with correct dimensionality
    main = layout[1,1] = init_main_trajectory_plot(
        ds, scene, idxs, lims, pinteg, colors, obs, plotkwargs
    )

    # here we define the main updating functionality
    run, sleslider = trajectory_plot_controls(scene, layout)

    isrunning = Observable(false)
    on(run) do clicks; isrunning[] = !isrunning[]; end
    on(run) do clicks
        @async while isrunning[]
        # while isrunning[]
            DynamicalSystems.step!(pinteg)
            for i in 1:length(u0s)
                ob = obs[i]
                # topush = iipcds ? @view(pinteg.u[:, i])[idxs] : pinteg.u[i][idxs]
                topush = DynamicalSystems.get_state(pinteg, i)[idxs]
                ob[] = push!(ob[], topush) # push and trigger update with `=`
            end
            sleslider[] == 0 ? yield() : sleep(sleslider[])
            isopen(scene) || break # crucial, ensures computations stop if closed window
        end
    end
    display(scene)
    scene, main, layout, obs
end

function init_trajectory_observables(L, pinteg, tail, idxs)
    obs = Observable[]
    T = length(idxs) == 2 ? Point2f0 : Point3f0
    for i in 1:L
        cb = CircularBuffer{T}(tail)
        fill!(cb, T(DynamicalSystems.get_state(pinteg, i)[idxs]))
        # append!(cb, rand(T, tail))
        push!(obs, Observable(cb))
    end
    return obs
end
trajectory_plot_type(::DynamicalSystems.ContinuousDynamicalSystem) = AbstractPlotting.lines!
trajectory_plot_type(::DynamicalSystems.DiscreteDynamicalSystem) = AbstractPlotting.scatter!
function init_main_trajectory_plot(ds, scene, idxs, lims, pinteg, colors, obs, plotkwargs)
    main = if (length(idxs) == 2)
        LAxis(scene)
    else
        if isnothing(lims)
            LScene(scene, scenekw = (camera = cam3d!, raw = false))
        else
            l = FRect3D((lims[1][1], lims[2][1], lims[3][1]),
            (lims[1][2] - lims[1][1], lims[2][2] - lims[2][1], lims[3][2] - lims[3][1]))
            LScene(scene, scenekw = (camera = cam3d!, raw = false, limits = l))
        end
    end
    for (i, ob) in enumerate(obs)
        if ds isa DynamicalSystems.ContinuousDynamicalSystem
            AbstractPlotting.lines!(main, ob;
                color = colors[i], linewidth = 4.0, plotkwargs...
            )
        else
            AbstractPlotting.scatter!(main, ob; color = colors[i],
                markersize = 5, strokewidth = 0.0, plotkwargs...
            )
        end
    end
    if !isnothing(lims)
        object_to_adjust = length(idxs) == 2 ? main : main.scene
        xlims!(object_to_adjust, lims[1])
        ylims!(object_to_adjust, lims[2])
        if length(idxs) > 2
            zlims!(object_to_adjust, lims[3])
            m = maximum(abs(x[2] - x[1]) for x in lims)
            a = [m/abs(x[2] - x[1]) for x in lims]
            scale!(object_to_adjust, a...)
        end
    end
    # TODO: Text font size is tiny, needs fixing (open proper issue at Makie.jl)
    return main
end
function trajectory_plot_controls(scene, layout)
    layout[2, 1] = controllayout = GridLayout(tellwidth = false)
    run = controllayout[1, 1] = LButton(scene; label = "run")
    _s, _v = 10.0 .^ (-5:0.1:0), 0.1
    pushfirst!(_s, 0.0)
    slesl = labelslider!(scene, "sleep =", _s;
    sliderkw = Dict(:startvalue => _v), valuekw = Dict(:width => 100),
    format = x -> "$(round(x; digits = 5))")
    controllayout[1, 2] = slesl.layout
    return run.clicks, slesl.slider.value
end


function traj_lim_estimator(ds, u0s, diffeq, idxs)
    tr = DynamicalSystems.trajectory(ds, 1000, u0s[1]; dt = 1, diffeq...)
    _mi, _ma = DynamicalSystems.minmaxima(tr)
    mi, ma = _mi[idxs], _ma[idxs]
    for i in 2:length(u0s)
        tr = DynamicalSystems.trajectory(ds, 1000, u0s[1]; dt = 1, diffeq...)
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
