# Visualizations and Animations for Billiards

## Interactive billiard
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/bill2.mp4?raw=true" type="video/mp4">
</video>
```
(see the `examples/billiard.jl` file to generate every animation)

```@docs
interactive_billiard
```

---

For example, running
```
using DynamicalBilliards, InteractiveDynamics, GLMakie
bd, = billiard_logo(T = Float32)
interactive_billiard(bd, 1f0, tail = 1000)
```
gives

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/bill1.mp4?raw=true" type="video/mp4">
</video>
```

## Billiard video

```@docs
billiard_video
```

Here is a video in the style of [3Blue1Brown](https://www.3blue1brown.com/)
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/3b1billiard.mp4?raw=true" type="video/mp4">
</video>
```

## Video with timeseries

```@docs
billiard_video_timeseries
```

For example running
```julia
using InteractiveDynamics, DynamicalBilliards, GLMakie

psize = 2.0

bd = billiard_stadium(1.0f0, 1.0f0) # must be type Float32

frames = 1800
dt = 0.0001
speed = 200
f(p) = p.pos[2] # the function that obtains the data from the particle
total_span = 10.0

ps = particlebeam(1.0, 0.8, 0, 2, 0.0001, nothing, Float32)
ylim = (0, 1)
ylabel = "y"

billiard_video_timeseries(
    videodir("timeseries.mp4"), bd, ps, f;
    displayfigure = true, total_span,
    frames, backgroundcolor = :black,
    plot_particles = true, tailwidth = 4, particle_size = psize, res = MAXRES,
    dt, speed, tail = 20000, # this makes ultra fine temporal resolution
    framerate = 60, ylabel
)
```

gives

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/billiard_timeseries.mp4?raw=true" type="video/mp4">
</video>
```


## Interactive with boundary map


```@docs
interactive_billiard_bmap
```

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/bmap.mp4?raw=true" type="video/mp4">
</video>
```

## Static plot with boundary map

```@docs
billiard_bmap_plot
```
