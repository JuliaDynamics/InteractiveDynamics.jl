# Interactive trajectory evolution
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/interactive_trajectory.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_evolution
```

---

To generate the above video run

```julia
using InteractiveChaos
using DynamicalSystems, Makie
using OrdinaryDiffEq
ds = Systems.henonheiles()

u0s = [[0.0, -0.25, 0.42081, 0.0],
[0.0, 0.1, 0.5, 0.0],
[0.0, -0.31596, 0.354461, 0.0591255]]

diffeq = (alg = Vern9(), dtmax = 0.01)
idxs = (1, 2, 4)
colors = ["#233B43", "#499cbf", "#E84646"]

scene, main, obs = interactive_evolution(
    ds, u0s; idxs, tail = 10000, diffeq, colors
)
```
