# Visualizations and Animations for Billiards

All plotting functionality of [DynamicalBilliards.jl](https://juliadynamics.github.io/DynamicalBilliards.jl/dev/) lies within a few well-defined functions from [InteractiveDynamics.jl](https://juliadynamics.github.io/InteractiveDynamics.jl/dev/) that use the [Makie](https://makie.juliaplots.org/stable/) ecosystem.

- For static plotting, you can use the function [`bdplot`](@ref).
- For interacting/animating, you can use the function [`bdplot_interactive`](@ref).
  This function also allows you to create custom animations, see [Custom Billiards Animations](@ref).
- For producing videos of time evolution of particles in a billiard, use [`bdplot_video`](@ref).

## Plotting
### Plotting an obstacle with keywords
```@example BILLIARDS
using DynamicalBilliards, InteractiveDynamics, CairoMakie

bd = billiard_sinai()

fig, ax = bdplot(bd[2])
bdplot!(ax, bd[4]; color = "blue", linestyle = :dot, linewidth = 5.0)
bdplot!(ax, bd[1]; color = "yellow", strokecolor = "black")
fig
```
### Plotting a billiard
```@example BILLIARDS
using DynamicalBilliards, InteractiveDynamics, CairoMakie
b = billiard_polygon(6, 1)
a = Antidot([0.0,0.0], 0.5)
bd = Billiard(b.obstacles..., a)
fig, ax = bdplot(bd)
fig
```

### Plotting some particle trajectories
```@example BILLIARDS
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
```

### Periodic billiard plots
#TODO:!!!!

## Interactive GUI
```@dos
bdplot_interactive
```

## Videos
```@docs
bdplot_video
```
Here is an example that changes plotting defaults to make an animation in the style of [3Blue1Brown](https://www.3blue1brown.com/).

```@example BILLIARDS
using DynamicalBilliards, InteractiveDynamics, CairoMakie

BLUE = "#7BC3DC"
BROWN = "#8D6238"
colors = [BLUE, BROWN]
# Overwrite default color of obstacles to white (to fit with black)
InteractiveDynamics.obcolor(::Obstacle) = RGBf(1,1,1)
bd = billiard_stadium(1, 1)
ps = particlebeam(1.0, 0.6, 0, 1000, 0.001)

bdplot_video(
    "3b1billiard.mp4", bd, ps;
    frames = 1200, backgroundcolor = :black, colors
)
```
```@raw html
<video width="auto" controls autoplay loop>
<source src="../3b1billiard.mp4" type="video/mp4">
</video>
```

## Custom Billiards Animations
To do custom animations you need to have a good idea of how Makie's animation system works. Have a look [at this tutorial](https://www.youtube.com/watch?v=L-gyDvhjzGQ) if you are not familiar yet.

Following the docstring of [`bdplot_interactive`](@ref) let's add a couple of new plots that animate some properties of the particles.
We start with creating the billiard plot and obtaining the observables:
```@example BILLIARDS
using DynamicalBilliards, InteractiveDynamics, CairoMakie

bd = billiard_stadium(1, 1)
N = 100
ps = particlebeam(1.0, 0.6, 0, N, 0.001)
fig, phs, chs = bdplot_interactive(bd, ps; playback_controls=false, resolution = (800, 800));
```
Then, we add some axis
```@example BILLIARDS
layout = fig[2,1] = GridLayout()
axd = Axis(layout[1,1]; ylabel = "log(⟨d⟩)")
axs = Axis(layout[2,1]; ylabel = "std", xlabel = "time")
hidexdecorations!(axd; grid = false)
rowsize!(fig.layout, 1, Auto(2))
fig
```
Our next step is to create new observables to plot in the new axis, by lifting `phs, chs`. Let's plot the distance between two particles and the std of the particle y position.
```@example BILLIARDS
using Statistics: std
# Define observables
d_p(phs) = log(sum(sqrt(sum(phs[1].p.pos .- phs[j].p.pos).^2) for j in 2:N)/N)
std_p(phs) = std(p.p.pos[1] for p in phs)
t = Observable([0.0]) # Time axis
d = Observable([d_p(phs[])])
s = Observable([std_p(phs[])])
# Trigger observable updates
on(phs) do phs
    push!(t[], phs[1].T)
    push!(d[], d_p(phs))
    push!(s[], std_p(phs))
    notify.((t, d))
    autolimits!(axd); autolimits!(axs)
end
# Plot observables
lines!(axd, t, d; color = JULIADYNAMICS_COLORS[1])
lines!(axs, t, s; color = JULIADYNAMICS_COLORS[2])
nothing
```
The figure hasn't changed yet of course, but after we step the animation, it does:
```@example BILLIARDS
dt = 0.001
for j in 1:1000
    for i in 1:9
        bdplot_animstep!(phs, chs, bd, dt; update = false)
    end
    bdplot_animstep!(phs, chs, bd, dt; update = true)
end
fig
```
Of course, you can produce a video of this using Makie's `record` function.