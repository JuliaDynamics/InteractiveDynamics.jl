using DynamicalBilliards, AbstractPlotting, MakieLayout
export interactive_billiard, interactive_billiard_bmap, billiard_video


"""
    interactive_billiard(bd::Billiard [, x, y, φ] [, ω=nothing]; kwargs...)
    interactive_billiard(bd::Billiard, ps::Vector{<:AbstractParticle}; kwargs...)

Launch an interactive application that evolves particles in a dynamical billiard `bd`, using
[DynamicalBilliards.jl](https://juliadynamics.github.io/DynamicalBilliards.jl/dev/).
Requires `DynamicalBilliards`.

You can either specify exactly the particles that will be used `ps` or provide
some initial conditions `x,y,φ,ω`, which by default are random in the billiard.
The particles are evolved in real time instead of being pre-calculated,
so the application can be left to run for infinite time.

See also [`interactive_billiard_bmap`](@ref) and [`billiard_video`](@ref).

## Interaction
Push "play" to start evolving particles in the billiard, and "reset" to restore them
to their (latest) initial condition. The "particles" hides or shows the particles.
The "speed" slider controls the animation speed (in fact, it controls how often
are the plots updated).

Clicking and dragging inside the billiard plot shows a line. When the line is selected,
new particles are created that have the direction of this line, as well as its starting
position, using the function `particlebeam` from `DynamicalBilliards`.

## Further keywords
* `N = 100` : if exact particles are not given, `N` are created. Otherwise it is `length(ps)`.
* `dx = 0.01` : width of the particle beam.
* `dt = 0.001` : time resolution of the animation.
* `tail = 1000` : length of the tail of the particles (multiplies `dt`).
* `colors = JULIADYNAMICS_COLORS` : If a symbol (colormap name) each particle gets
  a color from the map. If Vector of length `N`, each particle gets a color form the vector.
  If Vector with length < `N`, linear interpolation across contained colors is done.
* `fade = true` : Whether to add fadeout to the particle tail.
* `sleept = nothing` : If the slowest speed of the animation is already too fast,
  give a small number to `sleept`.
* `plot_particles = true` : If false, the particles are not plotted (as balls and arrows).
  This makes the application faster (you cannot show them again with the button).
"""
interactive_billiard(bd::Billiard, ω::Union{Nothing, Real} = nothing; kwargs...) =
interactive_billiard(bd::Billiard, randominside_xyφ(bd)..., ω; kwargs...)

function interactive_billiard(bd::Billiard, x::Real, y::Real, φ::Real, ω = nothing;
    kwargs...)
    N = get(kwargs, :N, 100)
    dx = get(kwargs, :dx, 0.01)
    ps = particlebeam(x, y, φ, N, dx, ω, Float32)
    interactive_billiard(bd::Billiard, ps; kwargs...)
end

function interactive_billiard(bd::Billiard, ps::Vector{<:AbstractParticle};
        dt = 0.001, tail = 1000, dx = 0.01, colors = JULIADYNAMICS_COLORS,
        plot_particles = true, α = 1.0, N = 100, res = (800, 800),
        intervals = nothing, sleept = nothing, fade = true,
        backgroundcolor = DEFAULT_BG,
        vr = _estimate_vr(bd),
        add_controls = true,
    )

    if eltype(bd) ≠ Float32 || eltype(ps[1]) ≠ Float32
        error("Only Float32 number type is possible for the billiard applications. "*
        "Please initialize billiards and particles by explicitly passing Float32 numbers "*
        "in all numeric fields (e.g. `bd = billiard_mushroom(1f0, 0.2f0, 1f0, 0f0)`)")
    end
    N = length(ps)
    p0s = deepcopy(ps) # deep is necessary because vector of mutables
    ω0 = ismagnetic(ps[1]) ? ps[1].ω : nothing

    # Initialized inside process
    cs = (!(colors isa Vector) || length(colors) ≠ N) ? colors_from_map(colors, α, N) : colors
    scene, layout = layoutscene(resolution = res, backgroundcolor = backgroundcolor)
    ax = layout[1, 1] = LAxis(scene, backgroundcolor = backgroundcolor)
    tight_ticklabel_spacing!(ax)
    ax.autolimitaspect = 1
    allparobs = [ParObs(p, bd, tail) for p in ps]
    bdplot!(ax, bd)

    # Plot tails
    for (i, p) in enumerate(allparobs)
        x = to_color(cs[i])
        if fade
            x = [RGBAf0(x.r, x.g, x.b, i/tail) for i in 1:tail]
        end
        lines!(ax, p.tail, color = x)
    end

    # Plot particles
    if plot_particles
        balls = Observable([Point2f0(p.p.pos) for p in allparobs])
        vels = Observable([vr * Point2f0(p.p.vel) for p in allparobs])
        particle_plots = (
            scatter!(ax, balls; color = darken_color.(cs), marker = MARKER, markersize = 12AbstractPlotting.px),
            arrows!(ax, balls, vels; arrowcolor = darken_color.(cs), linecolor = darken_color.(cs),
                normalize = false, arrowsize = 0.02AbstractPlotting.px,
                linewidth  = 4,
            )
        )
    end

    # Controls:
    if add_controls
        resetbutton = LButton(scene, label = "reset",
            buttoncolor = RGBf0(0.8, 0.8, 0.8),
            height = 40, width = 80
        )
        runbutton = LButton(scene, label = Observable("run"),
            buttoncolor = Observable(RGBf0(0.8, 0.8, 0.8)),
            buttoncolor_hover = Observable(RGBf0(0.7, 0.7, 0.9)),
            buttoncolor_active = Observable(RGBf0(0.6, 0.6, 1.0)),
            labelcolor = Observable((RGBf0(0,0,0))),
            labelcolor_active = Observable((RGBf0(1,1,1))),
            height = 40, width = 70,
        )
        nslider = LSlider(scene, range = 0:50, startvalue=0)
        controls = [resetbutton, runbutton, LText(scene, "speed:"), nslider]
        if plot_particles
            particlebutton = LButton(scene, label = "particles",
                buttoncolor = RGBf0(0.8, 0.8, 0.8),
                height = 40, width = 100
            )
            pushfirst!(controls, particlebutton)
        end

        # Functionality that CREATES the play/stop button
        # TODO: will be deleted once MakieLayout has proper togglable button
        on(runbutton.clicks) do n
            t = runbutton.label[] == "run" ? "stop" : "run"
            runbutton.label[] = t
            for (s1, s2) in ((:buttoncolor, :buttoncolor_active), (:labelcolor, :labelcolor_active))
            getproperty(runbutton, s1)[], getproperty(runbutton, s2)[] =
                getproperty(runbutton, s2)[], getproperty(runbutton, s1)[]
            end
            runbutton.labelcolor_hover[] = runbutton.labelcolor[]
        end

        # Create the "control panel"
        layout[2, 1] = grid!(hcat(
            controls...,
        ), tellwidth = false, tellheight = true)

        # Play/stop
        on(runbutton.clicks) do nclicks
            @async while runbutton.label[] == "stop"
                for i in 1:N
                    p = ps[i]
                    parobs = allparobs[i]
                    animstep!(parobs, bd, dt, true, intervals)
                    if plot_particles
                        balls[][i] = parobs.p.pos
                        vels[][i] = vr * parobs.p.vel
                    end
                end
                if plot_particles
                    balls[] = balls[]
                    vels[] = vels[]
                end
                for _ in 1:nslider.value[]
                    for i in 1:N
                        p = ps[i]
                        parobs = allparobs[i]
                        animstep!(parobs, bd, dt, false, intervals)
                    end
                end
                if sleept == nothing
                    yield()
                else
                    sleep(sleept)
                end
                isopen(scene) || break
            end
        end

        # Resetting
        on(resetbutton.clicks) do nclicks
            # update parobs
            for i in 1:N
                parobs = allparobs[i]
                rebind_partobs!(parobs, p0s[i], bd)
                if plot_particles
                    balls[][i] = parobs.p.pos
                    vels[][i] = vr * parobs.p.vel
                end
            end
            if plot_particles
                balls[] = balls[]
                vels[] = vels[]
            end
            yield()
        end

        # Show/hide particles
        if plot_particles
            on(particlebutton.clicks) do nclicks
                particle_plots[1].visible[] = !particle_plots[1].visible[]
                for i in 1:2
                particle_plots[2].plots[i].visible[] = !particle_plots[2].plots[i].visible[]
                end
            end
        end

        # Selecting new particles
        sline = select_line(ax.scene)
        on(sline) do val
            pos = val[1]
            dir = val[2] - val[1]
            φ = atan(dir[2], dir[1])
            p0s .= particlebeam(pos..., φ, N, dx, ω0, Float32)
            resetbutton.clicks[] += 1
        end

    end # adding controls blocks

    display(scene)
    if add_controls
        return scene, layout, allparobs, resetbutton, p0s, sline
    elseif plot_particles
        return scene, layout, allparobs, balls, vels, vr
    else
        return scene, layout, allparobs, nothing, nothing, nothing
    end
end




"""
    billiard(file, bd::Billiard [, x, y, φ] [, ω=nothing]; kwargs...)
    billiard(file, bd::Billiard, ps::Vector{<:AbstractParticle}; kwargs...)

Perform the same animation like in [`interactive_billiard`](@ref), but there is no
interaction; the result is saved directly as a video in `file` (no buttons are shown).

## Keywords
* `N, dt, tail, dx, colors, plot_particles, fade`: same as `interactive_billiard`, but
  with a bit "denser" defaults. `plot_particles` is `false` by default here.
* `speed = 4`: Animation "speed" (how many `dt` steps are taken before a frame is recorded)
* `frames = 1000`: amount of frames to record.
* `framerate = 60`: exported framerate.
* `backgroundcolor = RGBf0(0.99, 0.99, 0.99)`.
* `res = nothing`: resolution of the frames. If nothing, a resolution matching the
  the billiard aspect ratio is estimated. Otherwise pass a 2-tuple.
"""
billiard_video(file::String, bd::Billiard, ω::Union{Nothing, Real} = nothing; kwargs...) =
billiard_video(file::String, bd::Billiard, randominside_xyφ(bd)..., ω; kwargs...)

function billiard_video(file::String, bd::Billiard, x::Real, y::Real, φ::Real, ω = nothing;
    kwargs...)
    N = get(kwargs, :N, 500)
    dx = get(kwargs, :dx, 0.01)
    ps = particlebeam(x, y, φ, N, dx, ω, Float32)
    billiard_video(file, bd, ps; kwargs...)
end

function billiard_video(file::String, bd::Billiard, ps::Vector{<:AbstractParticle};
        plot_particles = false, res = nothing, dt = 0.001,
        speed = 4, frames = 1000, framerate = 60, kwargs...
    )

    if res == nothing
        xmin, ymin, xmax, ymax = DynamicalBilliards.cellsize(bd)
        aspect = (xmax - xmin)/(ymax-ymin)
        res = (round(Int, aspect*800), 800)
    end

    scene, layout, allparobs, balls, vels, vr = interactive_billiard(bd, ps;
        res = res, plot_particles=plot_particles, kwargs..., add_controls =false
    )
    N = length(ps)

    record(scene, file, 1:frames; framerate = framerate) do j
        for i in 1:N
            p = ps[i]
            parobs = allparobs[i]
            animstep!(parobs, bd, dt, true)
            if plot_particles
                balls[][i] = parobs.p.pos
                vels[][i] = vr * parobs.p.vel
            end
        end
        if plot_particles
            balls[] = balls[]
            vels[] = vels[]
        end
        for _ in 1:speed
            for i in 1:N
                p = ps[i]
                parobs = allparobs[i]
                animstep!(parobs, bd, dt, false)
            end
        end
    end
    return
end



"""
    interactive_billiard_bmap(bd::Billiard, ω=nothing; kwargs...)
Launch an interactive application whose left part is [`interactive_billiard`](@ref)
and whose write part is an interactive boundary map of the billiard (see "Phase spaces"
in DynamicalBilliards.jl).

A particle evolved in the real billiard is also shown on the boundary map.
All interaction of the billiard works as before, but there is also interaction in
the boundary map: clicking on it will generate a particle whose boundary map is
the clicked point.

The mean collision time "m.c.t." of the particle is shown as well.

## Keywords
* `newcolor = randomcolor` A function which takes as input `(pos, vel, ξ, sφ)` and
  outputs a color (for the scatter points in the boundary map).
* `ms = 12` markersize (in pixels).
* `dt, tail, sleept, fade` : propagated to `interactive_billiard`.
"""
function interactive_billiard_bmap(bd::Billiard, ω=nothing;
    newcolor = randomcolor, ms = 12, lock = true,
    kwargs...)

    intervals = arcintervals(bd)
    scene, layout, allparobs, resetbutton, p0s, sline = interactive_billiard(
        bd, ω; kwargs..., N = 1, intervals = intervals, res = (1600, 800)
    )
    parobs = allparobs[1] # only one exists.


    sublayout = GridLayout()
    cleanbutton = LButton(scene, label = "clean", tellwidth = false)
    sublayout[2, 1] = cleanbutton
    mct = Observable("m.c.t. = 0.0")
    mcttext = LText(scene, mct, haligh = :left, tellwidth = false)
    sublayout[2, 2] = mcttext
    bmapax = sublayout[1,:] = LAxis(scene)
    bmapax.xlabel = "arclength ξ"
    bmapax.ylabel = "normal angle sin(θ)"
    bmapax.targetlimits[] = BBox(intervals[1], intervals[end], -1, 1)

    current_color = Observable(newcolor(parobs.p.pos, parobs.p.vel, parobs.ξsin[]...))
    scatter_points = Observable(Point2f0[])
    scatter_colors = Observable(RGBAf0[])

    scatter!(bmapax.scene, scatter_points; color = scatter_colors,
        marker = MARKER, markersize = ms*AbstractPlotting.px
    )

    # Make obstacle axis, add info about where each obstacle terminates
    if length(intervals) > 2 # at least 2 obstacles
        add_obstacle_axis!(scene, sublayout, intervals, bmapax, lock)
    end

    # Obtain new color when selecting line in main plot
    on(sline) do val
        current_color[] = newcolor(parobs.p.pos, parobs.p.vel, parobs.ξsin[]...)
    end
    # Whenever boundary map is updated, plot the update
    on(parobs.ξsin) do v
        pushupdate!(scatter_points, v)
        pushupdate!(scatter_colors, current_color[])
        τ = parobs.T/parobs.n
        mct[] = "m.c.t. = $(rpad(string(τ), 25))"
    end

    # Selecting a point on the boundary map:
    spoint = select_point(bmapax.scene)
    on(spoint) do ξsin
        ξ, sφ = ξsin
        sφ = clamp(sφ, -1, 1)
        ξsin = Point2f0(ξ, sφ)
        if !(intervals[1] ≤ ξ ≤ intervals[end])
            error("selected point is outside the boundary map")
        end
        pos, vel = from_bcoords(ξsin..., bd, intervals)
        current_color[] = newcolor(pos, vel, ξsin...)
        p0s[1] = ω ≠ nothing ? MagneticParticle(pos, vel, ω) : Particle(pos, vel)
        propagate!(p0s[1], 10eps(Float32)) # ensure no bad behavior with boundary
        rebind_partobs!(parobs, p0s[1], bd, ξsin)
        resetbutton.clicks[] += 1 # reset main billiard
    end

    # Clean button functionality
    on(cleanbutton.clicks) do nclicks
        scatter_points[] = Point2f0[]
        scatter_colors[] = RGBAf0[]
    end

    # Lock zooming
    if lock
        bmapax.xpanlock = true
        bmapax.ypanlock = true
        bmapax.xzoomlock = true
        bmapax.yzoomlock = true
    end

    layout[:, 2] = sublayout
    display(scene)
    return scene, layout, parobs
end

function add_obstacle_axis!(scene, sublayout, intervals, bmapax, lock)
    ticklabels = ["$(round(ξ, sigdigits=4))" for ξ in intervals[2:end-1]]
    bmapax.xticks = (Float32[intervals[2:end-1]...], ticklabels)
    for (i, ξ) in enumerate(intervals[2:end-1])
        lines!(bmapax.scene, [Point2f0(ξ, -1), Point2f0(ξ, 1)], linestyle = :dash, color = :black)
    end
    obstacle_ticklabels = String[]
    obstacle_ticks = Float32[]
    for (i, ξ) in enumerate(intervals[1:end-1])
        push!(obstacle_ticks, ξ + (intervals[i+1] - ξ)/2)
        push!(obstacle_ticklabels, string(i))
    end

    obax = sublayout[1,:] = LAxis(scene)
    obax.xticks = (obstacle_ticks, obstacle_ticklabels)
    obax.xaxisposition = :top
    obax.xticklabelalign = (:center, :bottom)
    obax.xlabel = "obstacle index"
    obax.xgridvisible = false
    hideydecorations!(obax)
    hidespines!(obax)
    xlims!(obax, 0, intervals[end])
    if lock
        obax.xpanlock = true
        obax.ypanlock = true
        obax.xzoomlock = true
        obax.yzoomlock = true
    end
    return obax
end

export billiard_bmap_plot

"""
    billiard_bmap_plot(bd::Billiard, ps::Vector{<:AbstractParticle}; kwargs...)
Return a static scene which has particles plotted on both the real billiard as well
the boundary map, each with its own color (keyword `colors`), and the same color is used
for the corresponding scatter points in the boundary map.

All keyword arguments are the same as [`interactive_billiard_bmap`](@ref), besides
the interaction part of course.
"""
function billiard_bmap_plot(bd::Billiard, ps::Vector{<:AbstractParticle};
        ms = 8, plot_particles=true, colors = JULIADYNAMICS_COLORS,
        dt = 0.001, steps = round(Int, 10/dt), kwargs...
    )

    N = length(ps)
    intervals = arcintervals(bd)
    scene, layout, allparobs, balls, vels, vr = interactive_billiard(bd, ps;
        kwargs..., dt = dt, add_controls =false, plot_particles=plot_particles,
        intervals = intervals, res = (1600, 800), colors = colors
    )
    cs = (!(colors isa Vector) || length(colors) ≠ N) ? colors_from_map(colors, 1.0, N) : colors

    sublayout = GridLayout()
    bmapax = sublayout[1,1] = LAxis(scene)
    bmapax.xlabel = "arclength ξ"
    bmapax.ylabel = "normal angle sin(θ)"
    ylims!(bmapax, -1, 1)
    xlims!(bmapax, intervals[1], intervals[end])
    bmapax.xticklabelsize = 28
    bmapax.yticklabelsize = 28
    bmapax.xlabelsize = 36
    bmapax.ylabelsize = 36
    bmapax.ylabelpadding = 20
    if length(intervals) > 2 # at least 2 obstacles
        obax = add_obstacle_axis!(scene, sublayout, intervals, bmapax, false)
        obax.xticklabelsize = 28
        obax.yticklabelsize = 28
        obax.xlabelsize = 36
        obax.ylabelsize = 36
        obax.ylabelpadding = 20
    end


    # create listeners that update boundary map points
    all_bmap_scatters = [Point2f0[] for i in 1:N]
    for i in 1:N
        parobs = allparobs[i]
        vector = all_bmap_scatters[i]
        on(parobs.ξsin) do val
            push!(vector, val)
        end
    end

    # evolve particles until necessary time
    for j in 1:steps-1
        for i in 1:N
            p = ps[i]
            parobs = allparobs[i]
            animstep!(parobs, bd, dt, false, intervals)
            if plot_particles
                balls[][i] = parobs.p.pos
                vels[][i] = vr * parobs.p.vel
            end
        end
    end
    # last step (that actually updates plot)
    for i in 1:N
        p = ps[i]
        parobs = allparobs[i]
        animstep!(parobs, bd, dt, true)
    end
    if plot_particles
        balls[] = balls[]
        vels[] = vels[]
    end

    # Scatterplots:
    for i in 1:N
        c = cs[i]
        vector = all_bmap_scatters[i]
        scatter!(bmapax, vector; color = cs[i],
            marker = MARKER, markersize = ms*AbstractPlotting.px
        )
    end
    ylims!(bmapax, -1, 1)
    xlims!(bmapax, intervals[1], intervals[end])
    layout[:, 2] = sublayout
    return scene, bmapax
end
