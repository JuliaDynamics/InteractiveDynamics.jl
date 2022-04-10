# Interactive GUIs for Dynamical Systems

Via the package [InteractiveDynamics.jl](https://juliadynamics.github.io/InteractiveDynamics.jl/dev/)
we have created several GUI applications for exploring dynamical systems
which are integrated with [DynamicalSystems.jl](https://juliadynamics.github.io/DynamicalSystems.jl/dev/).
The GUI apps use the [Makie](https://makie.juliaplots.org/stable/) ecosystem,
and have been designed to favor generality and simple source code.
This means that even if one of the available GUI apps does not do what you'd like to
do, it should be easy to copy its source code and adjust accordingly!

## Interactive Trajectory Evolution

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/interactive_trajectory.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_evolution
```

For example, the animation on the top of this section was done with:

```julia
using InteractiveDynamics
using DynamicalSystems, GLMakie
using OrdinaryDiffEq

diffeq = (alg = Tsit5(), adaptive = false, dt = 0.01)
ps = Dict(
    1 => 1:0.1:30,
    2 => 10:0.1:50,
    3 => 1:0.01:10.0,
)
pnames = Dict(1 => "σ", 2 => "ρ", 3 => "β")

lims = (
    (-30, 30),
    (-30, 30),
    (0, 100),
)

ds = Systems.lorenz()

u1 = [10,20,40.0]
u3 = [20,10,40.0]
u0s = [u1, u3]

idxs = (1, 2, 3)
diffeq = (alg = Tsit5(), dt = 0.01, adaptive = false)

figure, obs, slidervals = interactive_evolution(
    ds, u0s; ps, idxs, tail = 1000, diffeq, pnames, lims
)

# Use the `slidervals` observable to plot fixed points
lorenzfp(ρ,β) = [
    Point3f(sqrt(β*(ρ-1)), sqrt(β*(ρ-1)), ρ-1),
    Point3f(-sqrt(β*(ρ-1)), -sqrt(β*(ρ-1)), ρ-1),
]

fpobs = lift(lorenzfp, slidervals[2], slidervals[3])
ax = content(figure[1,1][1,1])
scatter!(ax, fpobs; markersize = 5000, marker = :diamond, color = :black)
```

Notice that the last part of the code plots the fixed points of the system (something `interactive_evolution` does not do by itself), and the fixed points plots are automatically updated when a parameter is changed in the GUI.

## Cobweb Diagrams
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/cobweb.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_cobweb
```

The animation at the top of this section was done with

```julia
using InteractiveDynamics, GLMakie, DynamicalSystems

# the second range is a convenience for intermittency example of logistic
rrange = 1:0.001:4.0
# rrange = (rc = 1 + sqrt(8); [rc, rc - 1e-5, rc - 1e-3])

lo = Systems.logistic(0.4; r = rrange[1])
interactive_cobweb(lo, rrange, 5)
```

## Orbit Diagrams
*Notice that orbit diagrams and bifurcation diagrams are different things in DynamicalSystems.jl*
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/odhenon.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_orbitdiagram
scaleod
```

The animation at the top of this section was done with

```julia
i = p_index = 1
ds, p_min, p_max, parname = Systems.henon(), 0.8, 1.4, "a"
t = "orbit diagram for the Hénon map"

oddata = interactive_orbitdiagram(ds, p_index, p_min, p_max, i;
                                  parname = parname, title = t)

ps, us = scaleod(oddata)
```
