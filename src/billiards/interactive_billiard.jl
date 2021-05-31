export interactive_billiard, interactive_billiard_bmap,
       billiard_video, billiard_video_timeseries

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
* `tailwidth = 1` : Linewidth of the particle tail.
* `fade = true` : Whether to add fadeout to the particle tail.
* `sleept = nothing` : If the slowest speed of the animation is already too fast,
  give a small number to `sleept`.
* `plot_particles = true` : If false, the particles are not plotted (as balls and arrows).
  This makes the application faster (you cannot show them again with the button).
* `particle_size = 1.0` A multiplier for the size of the particles.
"""
interactive_billiard(bd::Billiard, ω::Union{Nothing, Real} = nothing; kwargs...) =
interactive_billiard(bd::Billiard, DynamicalBilliards.randominside_xyφ(bd)..., ω; kwargs...)

function interactive_billiard(bd::Billiard, x::Real, y::Real, φ::Real, ω = nothing;
    kwargs...)
    N = get(kwargs, :N, 100)
    dx = get(kwargs, :dx, 0.01)
    ps = DynamicalBilliards.particlebeam(x, y, φ, N, dx, ω, eltype(bd))
    interactive_billiard(bd::Billiard, ps; kwargs...)
end

function interactive_billiard(bd::Billiard, ps::Vector{<:AbstractParticle};
        dt = 0.001, tail = 1000, dx = 0.01, colors = JULIADYNAMICS_COLORS,
        plot_particles = true, α = 1.0, N = 100, res = (800, 800),
        intervals = nothing, sleept = nothing, fade = true,
        backgroundcolor = DEFAULT_BG,
        vr = _estimate_vr(bd),
        add_controls = true,
        displayfigure = true,
        tailwidth = 1,
        particle_size = 1.0,
    )

    N = length(ps)
    p0s = deepcopy(ps) # deep is necessary because vector of mutables
    ω0 = DynamicalBilliards.ismagnetic(ps[1]) ? ps[1].ω : nothing

    # Initialized inside process
    cs = if !(colors isa Vector) || length(colors) ≠ N
        colors_from_map(colors, α, N)
    else
        to_color.(colors)
    end
    figure = Figure(resolution = res, backgroundcolor = backgroundcolor)
    ax = figure[1, 1] = Axis(figure, backgroundcolor = backgroundcolor)
    tight_ticklabel_spacing!(ax)
    ax.autolimitaspect = 1
    allparobs = [ParObs(p, bd, tail) for p in ps]

    # Plot tails
    for (i, p) in enumerate(allparobs)
        x = to_color(cs[i])
        if fade
            x = [RGBAf0(x.r, x.g, x.b, i/tail) for i in 1:tail]
        end
        lines!(ax, p.tail; color = x, linewidth = tailwidth)
    end

    if plot_particles # plot ball and arrow as a particle
        balls = Observable([Point2f0(p.p.pos) for p in allparobs])
        vels = Observable([particle_size * vr * Point2f0(p.p.vel) for p in allparobs])
        particle_plots = (
            scatter!(
                ax, balls; color = darken_color.(cs),
                marker = MARKER, markersize = 8*particle_size*Makie.px,
                strokewidth = 0.0,
            ),
            arrows!(
                ax, balls, vels; arrowcolor = darken_color.(cs),
                linecolor = darken_color.(cs),
                normalize = false, arrowsize = particle_size*vr/3,
                linewidth  = particle_size*4,
            )
        )
    end

    # Plot billiard (after particles, so that obstacles hide the collision points)
    bdplot!(ax, bd)

    # Controls
    if add_controls
        resetbutton = Button(figure;
            label = "reset", buttoncolor = RGBf0(0.8, 0.8, 0.8),
            height = 40, width = 80
        )
        runbutton = Button(figure; label = Observable("run"),
            buttoncolor = Observable(RGBf0(0.8, 0.8, 0.8)),
            buttoncolor_hover = Observable(RGBf0(0.7, 0.7, 0.9)),
            buttoncolor_active = Observable(RGBf0(0.6, 0.6, 1.0)),
            labelcolor = Observable((RGBf0(0,0,0))),
            labelcolor_active = Observable((RGBf0(1,1,1))),
            height = 40, width = 70,
        )
        nslider = Slider(figure, range = 0:50, startvalue=0)
        controls = [resetbutton, runbutton, Label(figure, "speed:"), nslider]
        if plot_particles
            particlebutton = Button(figure, label = "particles",
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
        figure[2, 1] = grid!(hcat(controls...,), tellwidth = false, tellheight = true)

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
                isopen(figure.scene) || break
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
        MakieLayout.deactivate_interaction!(ax, :rectanglezoom)
        sline = select_line(ax.scene)
        on(sline) do val
            pos = val[1]
            dir = val[2] - val[1]
            φ = atan(dir[2], dir[1])
            p0s .= DynamicalBilliards.particlebeam(pos..., φ, N, dx, ω0, eltype(bd))
            resetbutton.clicks[] += 1
        end
    end # adding controls blocks

    displayfigure && display(figure)
    if add_controls
        return figure, allparobs, resetbutton, p0s, sline
    elseif plot_particles
        return figure, allparobs, balls, vels, vr
    else
        return figure, allparobs, nothing, nothing, nothing
    end
end




"""
    billiard_video(file, bd::Billiard [, x, y, φ] [, ω=nothing]; kwargs...)
    billiard_video(file, bd::Billiard, ps::Vector{<:AbstractParticle}; kwargs...)

Perform the same animation like in [`interactive_billiard`](@ref), but there is no
interaction; the result is saved directly as a video in `file` (no buttons are shown).

## Keywords
* `N, dt, tail, dx, colors, plot_particles, fade, tailwidth, backgroundcolor`:
  same as in `interactive_billiard`, but `plot_particles` is `false` by default here.
* `speed = 5`: Animation "speed" (how many `dt` steps are taken before a frame is recorded)
* `frames = 1000`: amount of frames to record.
* `framerate = 60`: exported framerate.
* `res = nothing`: resolution of the frames. If nothing, a resolution matching the
  the billiard aspect ratio is estimated. Otherwise pass a 2-tuple.

Notice that the animation performs an extra step for every `speed` steps and the
first frame saved is always at time 0. Therefore the following holds:
```julia
total_time = (frames-1)*(speed+1)*dt
time_covered_per_frame = (speed+1)*dt
```
"""
billiard_video(file::String, bd::Billiard, ω::Union{Nothing, Real} = nothing; kwargs...) =
billiard_video(file::String, bd::Billiard, DynamicalBilliards.randominside_xyφ(bd)..., ω; kwargs...)

function billiard_video(file::String, bd::Billiard, x::Real, y::Real, φ::Real, ω = nothing;
    kwargs...)
    N = get(kwargs, :N, 500)
    dx = get(kwargs, :dx, 0.01)
    ps = DynamicalBilliards.particlebeam(x, y, φ, N, dx, ω, eltype(bd))
    billiard_video(file, bd, ps; kwargs...)
end

function billiard_video(file::String, bd::Billiard, ps::Vector{<:AbstractParticle};
        plot_particles = false, res = nothing, dt = 0.001,
        speed = 5, frames = 1000, framerate = 60, kwargs...
    )

    dt = eltype(bd)(dt)
    if res == nothing
        xmin, ymin, xmax, ymax = DynamicalBilliards.cellsize(bd)
        aspect = (xmax - xmin)/(ymax-ymin)
        res = (round(Int, aspect*1000), 1000)
    end

    figure, allparobs, balls, vels, vr = interactive_billiard(bd, ps;
        res = res, plot_particles=plot_particles, kwargs..., add_controls = false,
        displayfigure = false
    )
    N = length(ps)

    Makie.inline!(true) # to not display figure while recording
    record(figure, file, 1:frames; framerate = framerate) do j
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
    Makie.inline!(false)
    return
end


"""
    billiard_video_timeseries(file, bd::Billiard, ps, f; kwargs...)

Perform the same animation like in [`billiard_video`](@ref), but in addition show the
timeseries of a chosen observable above the billiard. The observable is given using the
**function** `f`, which takes as an input a particle and outputs the observable.
E.g. `f(p) = p.pos[2]` or `f(p) = atan(p.vel[2], p.vel[1])`.
The video is saved directly into `file`.

## Keywords
* `N, dt, tail, dx, colors, plot_particles, fade, tailwidth, backgroundcolor`:
  same as in `interactive_billiard`.
* `speed, frames, framerate, res`: As in `billiard_video`.
* `total_span = 10.0`: Total span of the x-axis of the timeseries plot in real time units.
* `ylim = (0, 1)`: Limits of the y-axis of the timeseries plot.
* `ylabel = "f"`: Label of the y-axis of the timeseries plot.
"""
function billiard_video_timeseries(file::AbstractString, bd::Billiard, ps::Vector{<:AbstractParticle}, f;
        plot_particles = true, dt = 0.001,
        speed = 5, frames = 1000, framerate = 60,
        total_span = 10.0, colors = JULIADYNAMICS_COLORS,
        res = (800, 800), displayfigure = false, ylim = (0, 1),
        ylabel = "f",
        kwargs...
    )

    N = length(ps)
    tdt = total_span/20
    cs = if !(colors isa Vector) || length(colors) ≠ N
        colors_from_map(colors, α, N)
    else
        to_color.(colors)
    end
    dt = eltype(bd)(dt)

    figure, allparobs, balls, vels, vr = interactive_billiard(bd, ps;
        res, plot_particles, kwargs..., add_controls = false,
        displayfigure, colors = cs,
    )

    # Add the axis on the top
    tsax = figure[0, :] = Axis(figure; height = Relative(8/9))
    # Make the axis occupy 1/3 instead of 1/2:
    rowsize!(figure.layout, 1, Relative(1/3))
    tsax.xlabel = "time"
    tsax.ylabel = ylabel

    all_ts = [Observable([Point2f0(0, f(p))]) for p in ps]
    all_balls = [Observable(Point2f0(0, f(p))) for p in ps]

    for i in 1:length(ps)
        lines!(tsax, all_ts[i];
            color = cs[i],
            linewidth = 4,
        )
        scatter!(
            tsax, all_balls[i];
            markersize = 20*Makie.px,
            color = InteractiveDynamics.to_alpha(cs[i], 0.75),
            strokewidth = 0.0,
        )
    end
    ylims!(tsax, ylim)
    t_current = 0.0
    xlims!(tsax, -tdt, total_span+tdt)

    !displayfigure && Makie.inline!(true)
    record(figure, file, 1:frames; framerate = framerate) do j
        # This loop propagates the particles for `speed` steps but doesn't update the plot
        t_current += dt*speed
        for _ in 1:speed
            for i in 1:N
                p = ps[i]
                parobs = allparobs[i]
                InteractiveDynamics.animstep!(parobs, bd, dt, false)
            end
        end

        # This loop propagates the particles for 1 step & updates the plots
        t_current += dt
        for i in 1:N
            p = ps[i]
            parobs = allparobs[i]
            InteractiveDynamics.animstep!(parobs, bd, dt, true)
            # Update timeseries
            current_point = Point2f0(t_current, f(p))
            all_balls[i][] = current_point
            InteractiveDynamics.pushupdate!(all_ts[i], current_point)
            if plot_particles
                balls[][i] = parobs.p.pos
                vels[][i] = vr * parobs.p.vel
            end
        end
        if plot_particles
            balls[] = balls[]
            vels[] = vels[]
        end

        t_prev = max(0, t_current - total_span)
        xlims!(tsax, t_prev-tdt, max(t_current, total_span)+tdt)
    end
    !displayfigure && Makie.inline!(false)
    return figure
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
        newcolor = randomcolor, ms = 10, lock = true,
        kwargs...
    )

    intervals = DynamicalBilliards.arcintervals(bd)
    figure, allparobs, resetbutton, p0s, sline = interactive_billiard(
        bd, ω; kwargs..., N = 1, intervals = intervals, res = (1600, 800)
    )
    parobs = allparobs[1] # only one exists.

    sublayout = GridLayout()
    cleanbutton = Button(figure, label = "clean", tellwidth = false)
    sublayout[2, 1] = cleanbutton
    mct = Observable("m.c.t. = 0.0")
    mcttext = Label(figure, mct, haligh = :left, tellwidth = false)
    sublayout[2, 2] = mcttext
    bmapax = sublayout[1,:] = Axis(figure)
    bmapax.xlabel = "arclength, ξ"
    bmapax.ylabel = "sine of normal angle, sin(θ)"
    bmapax.targetlimits[] = BBox(intervals[1], intervals[end], -1, 1)

    current_color = Observable(newcolor(parobs.p.pos, parobs.p.vel, parobs.ξsin[]...))
    scatter_points = Observable(Point2f0[])
    scatter_colors = Observable(RGBAf0[])

    scatter!(bmapax.scene, scatter_points; color = scatter_colors,
        marker = MARKER, markersize = ms*Makie.px
    )

    # Make obstacle axis, add info about where each obstacle terminates
    if length(intervals) > 2 # at least 2 obstacles
        add_obstacle_axis!(figure, sublayout, intervals, bmapax, lock)
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
    MakieLayout.deactivate_interaction!(bmapax, :rectanglezoom)
    spoint = select_point(bmapax.scene)
    on(spoint) do ξsin
        ξ, sφ = ξsin
        sφ = clamp(sφ, -1, 1)
        ξsin = Point2f0(ξ, sφ)
        if !(intervals[1] ≤ ξ ≤ intervals[end])
            error("selected point is outside the boundary map")
        end
        pos, vel = DynamicalBilliards.from_bcoords(ξsin..., bd, intervals)
        current_color[] = newcolor(pos, vel, ξsin...)
        p0s[1] = ω ≠ nothing ? DynamicalBilliards.MagneticParticle(pos, vel, ω) : DynamicalBilliards.Particle(pos, vel)
        DynamicalBilliards.propagate!(p0s[1], 10eps(eltype(bd))) # ensure no bad behavior with boundary
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

    figure[:, 2] = sublayout
    display(figure)
    return figure, parobs
end

function add_obstacle_axis!(figure, sublayout, intervals, bmapax, lock)
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

    obax = sublayout[1,:] = Axis(figure)
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
Return a static figure which has particles plotted on both the real billiard as well
the boundary map, each with its own color (keyword `colors`), and the same color is used
for the corresponding scatter points in the boundary map.

All keyword arguments are the same as [`interactive_billiard_bmap`](@ref), besides
the interaction part of course. The additional keyword `steps` counts how many
times to progress the particles (in multiples of `dt`).
"""
function billiard_bmap_plot(bd::Billiard, ps::Vector{<:AbstractParticle};
        ms = 8, plot_particles=true, colors = JULIADYNAMICS_COLORS,
        dt = 0.001, steps = round(Int, 10/dt), kwargs...
    )

    N = length(ps)
    intervals = DynamicalBilliards.arcintervals(bd)
    figure, allparobs, balls, vels, vr = interactive_billiard(bd, ps;
        kwargs..., dt = dt, add_controls =false, plot_particles=plot_particles,
        intervals = intervals, res = (1600, 800), colors = colors
    )
    cs = (!(colors isa Vector) || length(colors) ≠ N) ? InteractiveDynamics.colors_from_map(colors, 1.0, N) : colors

    sublayout = GridLayout()
    bmapax = sublayout[1,1] = Axis(figure)
    bmapax.xlabel = "arclength, ξ"
    bmapax.ylabel = "sine of normal angle, sin(θ)"
    ylims!(bmapax, -1, 1)
    xlims!(bmapax, intervals[1], intervals[end])
    bmapax.xticklabelsize = 28
    bmapax.yticklabelsize = 28
    bmapax.xlabelsize = 36
    bmapax.ylabelsize = 36
    bmapax.ylabelpadding = 20
    if length(intervals) > 2 # at least 2 obstacles
        obax = add_obstacle_axis!(figure, sublayout, intervals, bmapax, false)
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
            marker = MARKER, markersize = ms*Makie.px
        )
    end
    ylims!(bmapax, -1, 1)
    xlims!(bmapax, intervals[1], intervals[end])
    figure[:, 2] = sublayout
    return figure, bmapax
end
