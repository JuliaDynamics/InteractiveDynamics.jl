######################################################################################
# Exported functions
######################################################################################
"""
    bdplot_interactive(bd::Billiard, ps::Vector{<:AbstractParticle}; kwargs...)
Create a new figure with `bd` plotted, and in it initialize various data for animating the
evolution of `ps` in `bd`. Return `fig, phs, chs`, where `fig` is a figure instance
and `phs, chs` can be used for making custom animations, see below.

## Keywords (interactivity-related)
* `playback_controls = true`: If true, add controls that allow live-interaction with
  the figure, such as pause/play, reset, and creating new particles by clicking
  and dragging on the billiard plot.

## Keywords (visualization-related)
* `dt = 0.001`: The animation always occurs in steps of time `dt`. A slider can decide
  how many steps `dt` to evolve before updating the plots.
* `plot_bmap = false`: If true, add a second plot with the boundary map.
* `colors = JULIADYNAMICS_CMAP` : If a symbol (colormap name) each particle gets
  a color from the map. If Vector of length `N`, each particle gets a color form the vector.
  If Vector with length < `N`, linear interpolation across contained colors is done.
* `tail_length = 1000`: The last `tail_length` positions of each particle are visualized.
* `tail_width = 1`: Width of the dtail plot.
* `fade = true`: Tail color fades away.
* `plot_particles = true`: Besides their tails, also plot the particles as a scatter
  and quiver plot.
* `particle_size = 5`: Marker size for particle scatter plot.
* `velocity_size = 0.05`: Multiplication of particle velocity before plotted as quiver.
* `bmap_size = 4`: Marker size of boundary map scatter plot.
* `backgroundcolor, resolution`: Background color and resolution of the created figure.

## Custom Animations
Two helper structures are defined for each particle:
1. `ParticleHelper`: Contains quantities that are updated each `dt` step:
   the particle, time elapsed since last collision, total time ellapsed, tail
   (positions in the last `tail_length` `dt`-sized steps).
2. `CollisionHelper`: Contains quantities that are only updated at collisions:
   index of obstacle to be collided with, time to next collision, total collisions so far,
   boundary map point at upcoming collision.

These two helpers are necessary to transform the simulation into real-time stepping
(1 step = `dt` time), instead of the traditional
DynamicalBilliards.jl setup of discrete time stepping (1 step = 1 collision).

The returned `phs, chs` are two observables, one having vector
of `ParticleHelpers`, the other having vector of `CollisionHelpers`.
Every plotted element is lifted from these observables.

An exported high-level function `bdplot_animstep!(phs, chs, bd, dt; update, intervals)`
progresses the simulation for one `dt` step.
Users should be using `bdplot_animstep!` for custom-made animations,
examples are shown in the documentation online.
The only thing the `update` keyword does is `notify!(phs)`. You can use `false` for it
if you want to step for several `dt` steps before updating plot elements.
Notice that `chs` is always notified when collisions occur irrespectively of `update`.
They keyword `intervals` is `nothing` by default, but if it is `arcintervals(bd)` instead,
then the boundary map field of `chs` is also updated at collisions.
"""
function bdplot_interactive(bd::Billiard, ps::Vector{<:AbstractParticle};
        playback_controls = true,
        dt = 0.001,
        plot_bmap = false,
        backgroundcolor = DEFAULT_BG,
        resolution = plot_bmap ? (1200, 600) : (800, 600),
        kwargs...
    )
    fig = Figure(;backgroundcolor, resolution)
    primary_layout = fig[:,1] = GridLayout()
    ax = Axis(primary_layout[1,1]; backgroundcolor = RGBAf(1,1,1,0))
    if plot_bmap
        intervals = DynamicalBilliards.arcintervals(bd)
        bmax = obstacle_axis!(fig[:,2], intervals)
    else
        bmax = nothing
        intervals = nothing
    end

    phs, chs, bmap_points = bdplot_plotting_init!(ax, bd, ps; bmax, kwargs...)
    ps0 = Observable(deepcopy(ps))

    if playback_controls
        control_observables = bdplot_animation_controls(fig, primary_layout)
        bdplot_control_actions!(
            fig, control_observables, phs, chs, bd, dt, ps0, intervals, bmap_points
        )
    end

    return fig, phs, chs
end

"""
    bdplot_video(file::String, bd::Billiard, ps::Vector{<:AbstractParticle}; kwargs...)
Create an animation of `ps` evolving in `bd` and save it into `file`.
This function shares all visualization-related keywords with [`bdplot_interactive`](@ref).
Other keywords are:
* `steps = 10`: How many `dt`-steps are taken between producing a new frame.
* `frames = 1000`: How many frames to produce in total.
* `framerate = 60`.
"""
function bdplot_video(file, bd::Billiard, ps::Vector{<:AbstractParticle};
        dt = 0.001, frames = 1000, steps = 10, plot_bmap = false,
        framerate = 60, kwargs...
    )
    fig, phs, chs = bdplot_interactive(bd, ps; playback_controls = false, plot_bmap, kwargs...)
    intervals = !plot_bmap ? nothing : DynamicalBilliards.arcintervals(bd)
    record(fig, file, 1:frames; framerate) do j
        for _ in 1:steps-1
            bdplot_animstep!(phs, chs, bd, dt; update = false, intervals)
        end
        bdplot_animstep!(phs, chs, bd, dt; update = true, intervals)
    end
    return
end

######################################################################################
# Internal interaction code
######################################################################################
function bdplot_animation_controls(fig, primary_layout)
    control_layout = primary_layout[2,:] = GridLayout(tellheight = true, tellwidth = false)

    height = 30
    resetbutton = Button(fig;
        label = "reset", buttoncolor = RGBf(0.8, 0.8, 0.8),
        height, width = 70
    )
    runbutton = Button(fig; label = "run",
        buttoncolor = RGBf(0.8, 0.8, 0.8), height, width = 70
    )
    stepslider = labelslider!(fig, "steps", 1:100; startvalue=1, height)
    # put them in the layout
    control_layout[:,1] = resetbutton
    control_layout[:,2] = runbutton
    control_layout[:,3] = stepslider.layout
    isrunning = Observable(false)
    rowsize!(primary_layout, 2, height)
    return isrunning, resetbutton.clicks, runbutton.clicks, stepslider.slider.value
end

function bdplot_control_actions!(
        fig, control_observables, phs, chs, bd, dt, ps0, intervals, bmap_points
    )
    isrunning, resetbutton, runbutton, stepslider = control_observables

    on(runbutton) do clicks; isrunning[] = !isrunning[]; end
    on(runbutton) do clicks
    @async while isrunning[] # without `@async`, Julia "freezes" in this loop
    # for jjj in 1:1000
            n = stepslider[]
            for _ in 1:n-1
                bdplot_animstep!(phs, chs, bd, dt; update = false, intervals)
            end
            bdplot_animstep!(phs, chs, bd, dt; update = true, intervals)
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window.
            yield()
        end
    end

    # Whenever initial particles are changed, trigger reset update
    on(ps0) do ps
        phs_vals, chs_vals = helpers_from_particles(deepcopy(ps), bd, length(phs[][1].tail))
        phs[] = phs_vals
        chs[] = chs_vals
        if !isnothing(bmap_points)
            for (bmp, c) in zip(bmap_points, chs[])
                bmp[] = [Point2f(c.ξsinθ)]
            end
        end
    end
    on(resetbutton) do clicks
        notify(ps0) # simply trigger initial particles change
    end

    # Selecting a line and making new particles
    ax = content(fig[1,1][1,1])
    MakieLayout.deactivate_interaction!(ax, :rectanglezoom)
    sline = select_line(ax.scene; color = JULIADYNAMICS_COLORS[1])
    dx = 0.001 # TODO: keyword
    ω0 = DynamicalBilliards.ismagnetic(ps0[][1]) ? ps0[][1].ω : nothing
    N = length(ps0[])
    on(sline) do val
        pos = val[1]
        dir = val[2] - val[1]
        φ = atan(dir[2], dir[1])
        ps0[] = DynamicalBilliards.particlebeam(pos..., φ, N, dx, ω0, eltype(bd))
    end

end

