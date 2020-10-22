# Billiards
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
using DynamicalBilliards, InteractiveChaos, Makie
bd, = billiard_logo(T = Float32)
interactive_billiard(bd, 1f0, tail = 1000)
```
gives

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/bill1.mp4?raw=true" type="video/mp4">
</video>
```

---

```@docs
billiard_video
```

Here is a video in the style of [3Blue1Brown](https://www.3blue1brown.com/)
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/3b1billiard.mp4?raw=true" type="video/mp4">
</video>
```

---

```@docs
interactive_billiard_bmap
```

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/bmap.mp4?raw=true" type="video/mp4">
</video>
```

---

```@docs
billiard_bmap_plot
```
