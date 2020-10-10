export interactive_evolution

# TODO: Estimate limits from dynamical system trajectories.

"""
    interactive_evolution(ds::DynamicalSystem, u0s; kwargs...)
Launch an interactive application that can evolve the initial conditions `u0s`
(vector of vectors) of the given dynamical system.
All initial conditions are evolved in parallel and at exactly the same time.
Two controls allow you to pause/resume the evolution and to adjust the speed.
The application can run forever (trajectories are computed on demand).

## Keywords
* `idxs = 1:min(dimension(ds), 3)` : Which variables to plot (up to three can be chosen).
* `colors` : The color for each trajectory. Random colors are chosen by default.
* `tail = 100` : Length of plotted trajectory (in step units).
* `dtmax = 0.01`: Maximum value for step size `dt` (valid for continuous systems).
* `diffeq = DynamicalSystems.CDS_KWARGS` : Named tuple of keyword arguments propagated to
  the solvers of DifferentialEquations.jl (for continuous systems).
* `lims = nothing` : A tuple of tuples (min, max) for the axis limits.
* `plotkwargs = NamedTuple()` : A named tuple of keyword arguments propagated to
  the plotting function (`lines` for continuous, `scatter` for discrete systems).
"""
function interactive_evolution(
    ds, u0s;
    colors = COLORSCHEME, idxs = 1:min(DynamicalSystems.dimension(ds), 3),
    dtmax = 0.01, tail = 1000, diffeq = DynamicalSystems.CDS_KWARGS,
    lims = nothing, plotkwargs = NamedTuple())

    @assert length(idxs) ≤ 3 "Only up to three variables can be plotted!"
    isnothing(lims) && @warn "It is strongly recommended to give the `lims` keyword!"
    idxs = SVector(idxs...)
    scene, layout = layoutscene()
    pinteg = DynamicalSystems.parallel_integrator(ds, u0s; dtmax = dtmax, diffeq...)
    obs = init_trajectory_observables(pinteg, tail, idxs)

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
            DynamicalSystems.step!(pinteg)
            for (i, ob) in enumerate(obs)
                ob[] = push!(ob[], pinteg.u[i][idxs]) # push and trigger update with `=`
            end
            sleslider[] == 0 ? yield() : sleep(sleslider[])
            isopen(scene) || break # crucial, ensures computations stop if closed window
        end
    end
    display(scene)
    scene, obs
end

function init_trajectory_observables(pinteg, tail, idxs)
    obs = Observable[]
    T = length(idxs) == 2 ? Point2f0 : Point3f0
    for u in pinteg.u
        cb = CircularBuffer{T}(tail)
        fill!(cb, T(u[idxs]))
        # append!(cb, rand(T, tail))
        push!(obs, Observable(cb))
    end
    return obs
end
trajectory_plot_type(::DynamicalSystems.ContinuousDynamicalSystem) = AbstractPlotting.lines!
trajectory_plot_type(::DynamicalSystems.DiscreteDynamicalSystem) = AbstractPlotting.scatter!
function init_main_trajectory_plot(ds, scene, idxs, lims, pinteg, colors, obs, plotkwrags)
    main = if (length(idxs) == 2)
        LAxis(scene)
    else
        if isnothing(lims)
            LScene(scene, scenekw = (camera = cam3d!, raw = false))
        else
            l = FRect3D((lims[1][1], lims[2][1], lims[3][1]), (lims[1][2], lims[2][2], lims[3][2]))
            LScene(scene, scenekw = (camera = cam3d!, raw = false, limits = l))

        end
    end
    for (i, ob) in enumerate(obs)
        if ds isa ContinuousDynamicalSystem
            AbstractPlotting.lines!(main, ob; color = colors[i], plotkwargs...)
        else
            AbstractPlotting.scatter!(main, ob; color = colors[i],
                markersize = 5, markerstrokewidth = 0.0, plotkwargs...
            )
        end
    end
    if !isnothing(lims)
        object_to_adjust = length(idxs) == 2 ? main : main.scene
        xlims!(object_to_adjust, lims[1])
        ylims!(object_to_adjust, lims[2])
        if length(idxs) > 2
            zlims!(object_to_adjust, lims[3])
            m = maximum(abs(-(x...)) for x in lims)
            a = [m/abs(-(x...)) for x in lims]
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
