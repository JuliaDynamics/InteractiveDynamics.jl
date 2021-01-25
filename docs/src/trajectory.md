# Interactive trajectory evolution
## Without timeseries
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/interactive_trajectory.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_evolution
```

To generate the video at the start of this page run

```julia
using InteractiveDynamics
using DynamicalSystems, GLMakie
using OrdinaryDiffEq

ds = Systems.henonheiles()  # 4D chaotic/regular continuous system

u0s = [[0.0, -0.25, 0.42081, 0.0],
[0.0, 0.1, 0.5, 0.0],
[0.0, -0.31596, 0.354461, 0.0591255]]

diffeq = (alg = Vern9(), dtmax = 0.01)
idxs = (1, 2, 4)
colors = ["#233B43", "#499cbf", "#E84646"]

figure, obs = interactive_evolution(
    ds, u0s; idxs, tail = 10000, diffeq, colors
)
```

And here is another version for a discrete system:
```julia
using InteractiveDynamics
using DynamicalSystems, GLMakie

ds = Systems.towel() # 3D chaotic discrete system
u0s = [0.1ones(3) .+ 1e-3rand(3) for _ in 1:3]

figure, obs = interactive_evolution(
    ds, u0s; idxs = SVector(1, 2, 3), tail = 100000,
)
```

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/towel_trajectory.mp4?raw=true" type="video/mp4">
</video>
```


## With timeseries
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/interactive_trajectory_timeseries.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_evolution_timeseries
```
