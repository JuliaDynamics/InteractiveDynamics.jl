using DynamicalBilliards, InteractiveChaos, Makie, MakieLayout

# TODO: plot particle as well!
# TODO: Allow input particles to be both `nothing` as well as specified
# TODO: input color can be vector of length N or colormap specifier
# TODO: N must be established to be the length of particles for both beam or input

# Input
dt = 0.001
tail = 1000 # multiple of dt
N = 100
plot_particles = true
colors = :dense
colors = [Makie.RGBAf0(i/N, 0, 1 - i/N, 0.25) for i in 1:N]
bd = billiard_stadium(1.0f0, 1.0f0)
bd = Billiard(bd..., Disk(SVector(0.5f0, 0.5f0), 0.2f0))
ps = [MagneticParticle(1, 0.6f0 + 0.0005f0*i, 0, 1f0) for i in 1:N]

function particlebeam(x0, y0, φ, N, dx, ω = nothing)
    n = sincos(φ)
    xyφs = [
    Float32.((x0 + i*dx*n[1]/N, y0 + i*dx*n[2]/N, φ)) for i in range(-N/2, N/2; length = N)
    ]
    if isnothing(ω)
        ps = [Particle(z...) for z in xyφs]
    else
        ps = [MagneticParticle(z..., Float32(ω)) for z in xyφs]
    end
end

ps = particlebeam(0.8, 0.6, 0, N, 0.01, 1.5)
p0s = deepcopy(ps) # deep is necessary because vector of mutables

# Initialized inside process
cs = colors isa Symbol ? AbstractPlotting.to_colormap(colors, N) : colors
scene, layout = layoutscene(resolution = (1000, 800))
ax = layout[1, 1] = LAxis(scene)
ax.autolimitaspect = 1
allparobs = [ParObs(p, bd, tail) for p in ps]
bdplot!(ax, bd)

# Plot particles (will be reused in resetting and making new particles)
partmarker = Circle(Point2f0(0, 0), Float32(1))

# Plot tails
for (i, p) in enumerate(allparobs)
    lines!(ax, p.tail, color = cs[i])
    # Not working:
    # scatter!(ax, [p.pos]; color = cs[i], marker = partmarker, markersize = 6*AbstractPlotting.px)
end

# Plot particles
if plot_particles
    vr = _estimate_vr(bd)
    balls = Observable([Point2f0(p.p.pos) for p in allparobs])
    vels = Observable([vr * Point2f0(p.p.vel) for p in allparobs])
    particle_plots = (
        scatter!(ax, balls; color = cs, marker = partmarker, markersize = 6AbstractPlotting.px),
        arrows!(ax, balls, vels; arrowcolor = cs, linecolor = cs,
            normalize = false, arrowsize = 0.01AbstractPlotting.px,
            linewidth  = 2,
        )
    )
end

function _estimate_vr(bd)
    xmin, ymin, xmax, ymax = DynamicalBilliards.cellsize(bd)
    f = max((xmax-xmin), (ymax-ymin))
    isinf(f) && error("cellsize of billiard is infinite")
    vr = Float32(f/50)
end

# Controls:
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
nslider = LSlider(scene, range = 0:30, startvalue=0)
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
), width = Auto(false), height = Auto(true))

# Play/stop functionality
on(runbutton.clicks) do nclicks
    @async while runbutton.label[] == "stop"
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
        for _ in 1:nslider.value[]
            for i in 1:N
                p = ps[i]
                parobs = allparobs[i]
                animstep!(parobs, bd, dt, false)
            end
        end
        yield()
        isopen(scene) || break
    end
end

# Resetting functionality
on(resetbutton.clicks) do nclicks
    if runbutton.label[] == "stop"
        runbutton.clicks[] += 1 # TODO: this is a hack until full support for LToggleButton
    end
    yield()
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

# Show/hide particles functionality
if plot_particles
    on(particlebutton.clicks) do nclicks
        particle_plots[1].visible[] = !particle_plots[1].visible[]
        for i in 1:2
        particle_plots[2].plots[i].visible[] = !particle_plots[2].plots[i].visible[]
        end
    end
end

display(scene)
