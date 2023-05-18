# Interactive GUIs for Dynamical Systems

Via the package [InteractiveDynamics.jl](https://juliadynamics.github.io/InteractiveDynamics.jl/dev/)
we have created several GUI applications for exploring dynamical systems
which are integrated with [DynamicalSystems.jl](https://juliadynamics.github.io/DynamicalSystems.jl/dev/).
The GUI apps use the [Makie](https://makie.juliaplots.org/stable/) ecosystem,
and have been designed to favor generality and simple source code.
This means that even if one of the available GUI apps does not do what you'd like to
do, it should be easy to copy its source code and adjust accordingly!

This documentation page is built using versions:
```@example DynamicalSystemsInter
using Pkg
Pkg.status(["DynamicalSystems", "InteractiveDynamics"];
    mode = PKGMODE_MANIFEST, io=stdout
)
```

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

figure, obs, step, slidervals = interactive_evolution(
    ds, u0s; ps, idxs, tail = 1000, diffeq, pnames, lims
)

# Use the `slidervals` observable to plot fixed points
lorenzfp(ρ,β) = [
    Point3f(sqrt(β*(ρ-1)), sqrt(β*(ρ-1)), ρ-1),
    Point3f(-sqrt(β*(ρ-1)), -sqrt(β*(ρ-1)), ρ-1),
]

fpobs = lift(lorenzfp, slidervals[2], slidervals[3])
ax = content(figure[1,1][1,1])
scatter!(ax, fpobs; markersize = 20, marker = :diamond, color = :black)
```

Notice that the last part of the code plots the fixed points of the system (something `interactive_evolution` does not do by itself), and the fixed points plots are automatically updated when a parameter is changed in the GUI, because it uses the observable `paramvals`.

### Customized animations
It is straightforward to add custom plots and generate extra animations from the interface of the `step` observable returned by [`interactive_evolution`](@ref). In the following example we'll make a video that rotates around some interlaced periodic trajectories, and plot some stuff from them on an extra panel to the right.

```@example DynamicalSystemsInter
using DynamicalSystems, InteractiveDynamics, CairoMakie
using OrdinaryDiffEq: Tsit5
using LinearAlgebra: dot, norm

ds = Systems.thomas_cyclical(b = 0.2)
u0s = ([3, 1, 1.], [1, 3, 1.], [1, 1, 3.])
diffeq = (alg = Tsit5(), adaptive = false, dt = 0.05)

fig, obs, step, = interactive_evolution(
    ds, u0s; tail = 1000, diffeq, add_controls = false, tsidxs = nothing,
    # Replace this with [1, 2, 3] if using GLMakie (looks much cooler ;))
    idxs = [1, 2],
    figure = (resolution = (1200, 600),),
)
axss = content(fig[1,1][1,1])
axss.title = "State space (projected)"

# Plot some stuff on a second axis that use `obs`
# Plot distance of trajectory from symmetry line
ax = Axis(fig[1,1][1,2]; xlabel = "points", ylabel = "distance")
function distance_from_symmetry(u)
    v = 0*SVector(u...) .+ 1/√(length(u))
    t = dot(v, u)
    return norm(u - t*v)
end
for (i, ob) in enumerate(obs)
    y = lift(x -> distance_from_symmetry.(x) .+ 4(i-1), ob)
    x = 1:length(y[])
    lines!(ax, x, y; color = JULIADYNAMICS_COLORS[i])
end
ax.limits = ((0, 1000), (0, 12))
fig
```

Now we can step this animation arbitrarily many times
```@example DynamicalSystemsInter
for j in 1:500; step[] = 0; end
fig
```

```@example DynamicalSystemsInter
for j in 1:500; step[] = 0; end
fig
```

Or we could produce a video with:
```julia
record(fig, "thomas_cyclical.mp4"; framerate = 60) do io
    for i in 1:720
        recordframe!(io)
        # Step multiple times per frame for "faster" animation
        for j in 1:5; step[] = 0; end
    end
end
```
