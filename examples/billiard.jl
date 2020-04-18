using DynamicalBilliards, InteractiveChaos, Makie, MakieLayout

# TODO: Fix magnetic particles!
# TODO: plot particle as well!
# TODO: Add reset button
# TODO: Allow input particles to be both `nothing` as well as specified
# TODO: input color can be vector of length N or colormap specifier

dt = 0.001
tail = 500 # multiple of dt
N = 100

bd = billiard_stadium(1.0f0, 1.0f0)
bd = Billiard(bd..., Disk(SVector(0.5f0, 0.5f0), 0.2f0))
cs = [Makie.RGBAf0(i/N, 0, 1 - i/N, 0.25) for i in 1:N]
ps = [Particle(1, 0.6f0 + 0.0005f0*i, 0) for i in 1:N]
ps = [Particle(1, 0.6f0 + 0.0005f0*i, 0) for i in 1:N]
# scale_plot=false
scene, layout = layoutscene(resolution = (800, 800))
ax = layout[1, 1] = LAxis(scene)
ax.autolimitaspect = 1
# bdplot!(ax, bd[1])
# bdplot!(ax, bd[2])
# bdplot!(ax, bd[3])
# bdplot!(ax, bd[4])
# bdplot!(ax, bd[5])
bdplot!(ax, bd)

allparobs = [ParObs(p, bd, tail) for p in ps]
plotted_tails_idxs = zeros(Int, N)
L = length(ax.scene.plots)
for (i, p) in enumerate(allparobs)
    lines!(ax, p.tail, color = cs[i])
    plotted_tails_idxs[i] = L + i
end
# delete!(ax.scene.plots, plotted_tails_idxs)

# Controls:
runtoggle = LToggle(scene, active = false)
nslider = LSlider(scene, range = 0:10, startvalue=0)
layout[2, 1] = grid!(hcat(
    LText(scene, "run:"), runtoggle, LText(scene, "speed:"), nslider
), width = Auto(false), height = Auto(true))

# Toggle test
on(runtoggle.active) do act
    @async while runtoggle.active[]
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

display(scene)
