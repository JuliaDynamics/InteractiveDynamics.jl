using DynamicalBilliards, InteractiveChaos, Makie, MakieLayout

# TODO: Fix magnetic particles!
# TODO: plot particle as well!
# TODO: Add reset button

# %% test
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
runtoggle = LToggle(scene, active = false)
dtslider = LSlider(scene, range = 1:100)
layout[2, 1] = grid!(hcat(
    LText(scene, "run:"), runtoggle, LText(scene, "speed:"), dtslider
), width = Auto(false), height = Auto(true))

# Toggle test
# TODO: I need to change my animation to not update a plot all the time...
on(runtoggle.active) do act
    @async while runtoggle.active[]
        # nsims = dtslider.value[]
        # for j in 1:nsims
            for i in 1:N
                p = ps[i]
                parobs = allparobs[i]
                animstep!(p, bd, dt, parobs)
            end
        # end
        # for j in 1:maximum(dtslider.range)-nsims
        #     for i in 1:N
        #         p = ps[i]
        #         parobs = allparobs[i]
        #         animstep!(p, bd, dt, parobs, true)
        #     end
        # end
        yield()
        # yield()
        isopen(scene) || break
    end
end

display(scene)

# layout[4, 1] = controlgrid = GridLayout(width = Auto(false), height = Auto(false))
# runbutton = LButton(scene, label = "run")
# stopbutton = LButton(scene, label = "stop")
# doesitrun = Observable(false)
# controlgrid[1, 1:2] = [runbutton, stopbutton]
#
# on(runbutton.clicks) do c
#     doesitrun[] = true
# end
# on(stopbutton.clicks) do c
#     doesitrun[] = false
# end
# on(doesitrun) do run
#     if doesitrun[]
#         for j in 1:1000
#             for i in 1:N
#                 p = ps[i]
#                 parobs = allparobs[i]
#                 animstep!(p, bd, dt, parobs)
#             end
#             yield()
#             isopen(scene) || break
#         end
#     end
# end


# #
# for _ in 1:1000
#     for i in 1:N
#         p = ps[i]
#         parobs = allparobs[i]
#         animstep!(p, bd, dt, parobs)
#     end
#     yield()
# end

# initialize all the stuff

# # %%
# using BenchmarkTools, DataStructures
# # TODO: try https://juliacollections.github.io/DataStructures.jl/latest/circ_buffer/
# n = 100
# x = [Point2f0(0.5, 0.5) for i in 1:n]
# @btime (popfirst!(v); push!(v, Point2f0(1.0, 1.0))) setup=(v=copy(x));
# @btime popfirst!(push!(v, Point2f0(1.0, 1.0))) setup=(v=copy(x));
#
# cb = CircularBuffer{Point2f0}(n)
# append!(cb, x)
#
# @btime push!(c, Point2f0(0.1, 0.1)) setup = (c=copy(cb))

# TODO: Don't update plots in every step. This will allow smaller `dt`, (higher resolution)
# but not updating at every dt. instead every 10 dt or so.
# Establish a benchmarking scenario of 1000 particles with 100 tail
# BUT this is not possible with the circular datastrcuture... I need to append at aevery point
# But I can update the plot stuff at NOT every point. This will mean that the
# particle pos and tail and the actual plotted observables are different and instead
# once every time the update happens.
