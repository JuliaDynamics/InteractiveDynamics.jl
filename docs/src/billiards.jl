# # Visualizations and Animations for Billiards

# All plotting and animating for [DynamicalBilliards.jl](https://juliadynamics.github.io/DynamicalBilliards.jl/dev/) lies within a few well-defined functions from [InteractiveDynamics.jl](https://juliadynamics.github.io/InteractiveDynamics.jl/dev/) that use the [Makie](https://makie.juliaplots.org/stable/) ecosystem.

# - For static plotting, you can use the function [`bdplot`](@ref).
# - For interacting/animating, you can use the function [`bdplot_interactive`](@ref).
#   This function also allows you to create custom animations, see [Custom Billiards Animations](@ref).
# - For producing videos of time evolution of particles in a billiard, use [`bdplot_video`](@ref).

# ## Plotting
# ```@docs
# bdplot
# ```
# ### Plotting an obstacle with keywords
using DynamicalBilliards, InteractiveDynamics, CairoMakie

bd = billiard_sinai()

fig, ax = bdplot(bd[2])
bdplot!(ax, bd[4]; color = "blue", linestyle = :dot, linewidth = 5.0)
bdplot!(ax, bd[1]; color = "yellow", strokecolor = "black")
fig

# ### Plotting a billiard
# %% #src
using DynamicalBilliards, InteractiveDynamics, CairoMakie
bd = billiard_logo()[1]
fig, ax = bdplot(bd)
fig

# ### Plotting some particle trajectories
# %% #src
using DynamicalBilliards, InteractiveDynamics, CairoMakie

bd = billiard_hexagonal_sinai()
p1 = randominside(bd)
p2 = randominside(bd, 1.0)
colors = [:red, JULIADYNAMICS_COLORS[1]]
markers = [:circle, :rect]
fig, ax = bdplot(bd)
for (p, c) in zip([p1, p2], colors)
    x, y = DynamicalBilliards.timeseries!(p, bd, 20)
    lines!(ax, x, y; color = c)
end
bdplot!(ax, [p1, p2]; colors, particle_size = 10, marker = markers)
fig

# ### Periodic billiard plot
# Rectangle periodicity:
# %% #src
using DynamicalBilliards, InteractiveDynamics, CairoMakie

r = 0.25
bd = billiard_rectangle(2, 1; setting = "periodic")
d = Disk([0.5, 0.5], r)
d2 = Ellipse([1.5, 0.5], 1.5r, 2r/3)
bd = Billiard(bd.obstacles..., d, d2)
p = Particle(1.0, 0.5, 0.1)
xt, yt, vxt, vyt, t = DynamicalBilliards.timeseries!(p, bd, 10)
fig, ax = bdplot(bd, extrema(xt)..., extrema(yt)...)
lines!(ax, xt, yt)
bdplot!(ax, p; velocity_size = 0.1)
fig

# Hexagonal periodicity:
# %% #src
using DynamicalBilliards, InteractiveDynamics, CairoMakie

bd = billiard_hexagonal_sinai(0.3, 1.50; setting = "periodic")
d = Disk([0.7, 0], 0.2)
d2 = Antidot([0.7/2, 0.65], 0.35)
bd = Billiard(bd..., d, d2)

p = MagneticParticle(-0.5, 0.5, π/5, 1.0)

xt, yt = DynamicalBilliards.timeseries(p, bd, 10)
fig, ax = bdplot(bd, extrema(xt)..., extrema(yt)...)
lines!(ax, xt, yt)
bdplot!(ax, p; velocity_size = 0.1)
fig

# ## Interactive GUI
# ```@docs
# bdplot_interactive
# ```

# ## Custom Billiards Animations
# %% #src
# To do custom animations you need to have a good idea of how Makie's animation system works.
# Have a look [at this tutorial](https://www.youtube.com/watch?v=L-gyDvhjzGQ) if you are
# not familiar yet.

# Following the docstring of [`bdplot_interactive`](@ref) let's add a couple of
# new plots that animate some properties of the particles.
# We start with creating the billiard plot and obtaining the observables:
using DynamicalBilliards, InteractiveDynamics, CairoMakie

bd = billiard_stadium(1, 1)
N = 100
ps = particlebeam(1.0, 0.6, 0, N, 0.001)
fig, phs, chs = bdplot_interactive(bd, ps; playback_controls=false, resolution = (800, 800));
# Then, we add some axis
layout = fig[2,1] = GridLayout()
axd = Axis(layout[1,1]; ylabel = "log(⟨d⟩)", align = Outside())
axs = Axis(layout[2,1]; ylabel = "std", xlabel = "time", align = Outside())
hidexdecorations!(axd; grid = false)
rowsize!(fig.layout, 1, Auto(2))
fig
# Our next step is to create new observables to plot in the new axis,
# by lifting `phs, chs`. Let's plot the distance between two particles and the
#  std of the particle y position.
using Statistics: std
## Define observables
d_p(phs) = log(sum(sqrt(sum(phs[1].p.pos .- phs[j].p.pos).^2) for j in 2:N)/N)
std_p(phs) = std(p.p.pos[1] for p in phs)
t = Observable([0.0]) # Time axis
d = Observable([d_p(phs[])])
s = Observable([std_p(phs[])])
## Trigger observable updates
on(phs) do phs
    push!(t[], phs[1].T)
    push!(d[], d_p(phs))
    push!(s[], std_p(phs))
    notify.((t, d))
    autolimits!(axd); autolimits!(axs)
end
## Plot observables
lines!(axd, t, d; color = JULIADYNAMICS_COLORS[1])
lines!(axs, t, s; color = JULIADYNAMICS_COLORS[2])
nothing

# The figure hasn't changed yet of course, but after we step the animation, it does:
dt = 0.001
for j in 1:1000
    for i in 1:9
        bdplot_animstep!(phs, chs, bd, dt; update = false)
    end
    bdplot_animstep!(phs, chs, bd, dt; update = true)
end
fig

# Of course, you can produce a video of this using Makie's `record` function.

# ## Video output
# ```@docs
# bdplot_video
# ```
# Here is an example that changes plotting defaults to make an animation in
# the style of [3Blue1Brown](https://www.3blue1brown.com/).
# %% #src
using DynamicalBilliards, InteractiveDynamics, CairoMakie

BLUE = "#7BC3DC"
BROWN = "#8D6238"
colors = [BLUE, BROWN]
## Overwrite default color of obstacles to white (to fit with black background)
InteractiveDynamics.obcolor(::Obstacle) = RGBf(1,1,1)
bd = billiard_stadium(1, 1)
ps = particlebeam(1.0, 0.6, 0, 200, 0.01)

bdplot_video(
    "3b1billiard.mp4", bd, ps;
    frames = 120, colors, dt = 0.01, tail_length = 100,
    backgroundcolor = :black,
)
nothing

# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../3b1billiard.mp4" type="video/mp4">
# </video>
# ```
