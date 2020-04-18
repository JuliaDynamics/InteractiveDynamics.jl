using DynamicalBilliards, InteractiveChaos, Makie, MakieLayout

# TODO: plot particle as well!
# TODO: Add reset button
# TODO: Allow input particles to be both `nothing` as well as specified
# TODO: input color can be vector of length N or colormap specifier

# Input
dt = 0.001
tail = 1000 # multiple of dt
N = 100
colors = [Makie.RGBAf0(i/N, 0, 1 - i/N, 0.25) for i in 1:N]
# colors = :dense
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

ps = particlebeam(0.8, 0.6, 0, N, 0.01, 1.0)

# Initialized inside process
cs = colors isa Symbol ? AbstractPlotting.to_colormap(colors, n = N) : colors
scene, layout = layoutscene(resolution = (1000, 800))
ax = layout[1, 1] = LAxis(scene)
ax.autolimitaspect = 1
bdplot!(ax, bd)

allparobs = [ParObs(p, bd, tail) for p in ps]
plotted_tails_idxs = zeros(Int, N)
L = length(ax.scene.plots)
for (i, p) in enumerate(allparobs)
    lines!(ax, p.tail, color = cs[i])
    plotted_tails_idxs[i] = L + i
end
# delete!(ax.scene.plots, plotted_tails_idxs) # do this to clean the scene

# Controls:
nslider = LSlider(scene, range = 0:10, startvalue=0)
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
    # width = Auto(false),
)


# Functionality that CREATES the play/stop button
on(runbutton.clicks) do n
    t = runbutton.label[] == "run" ? "stop" : "run"
    runbutton.label[] = t
    for (s1, s2) in ((:buttoncolor, :buttoncolor_active), (:labelcolor, :labelcolor_active))
    getproperty(runbutton, s1)[], getproperty(runbutton, s2)[] =
        getproperty(runbutton, s2)[], getproperty(runbutton, s1)[]
    end
    runbutton.labelcolor_hover[] = runbutton.labelcolor[]
end


layout[2, 1] = grid!(hcat(
    runbutton, resetbutton, LText(scene, "speed:"), nslider
), width = Auto(false), height = Auto(true))

# Play/stop functionality
on(runbutton.clicks) do nclicks
    @async while runbutton.label[] == "stop"
        for i in 1:N
            p = ps[i]
            parobs = allparobs[i]
            animstep!(parobs, bd, dt, true)
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

display(scene)

# for _ in 1:1000
#     for i in 1:N
#         p = ps[i]
#         parobs = allparobs[i]
#         animstep!(parobs, bd, dt, true)
#     end
# end
