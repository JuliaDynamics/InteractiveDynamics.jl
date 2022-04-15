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

figure, obs, step, paramvals = interactive_evolution(
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

Notice that the last part of the code plots the fixed points of the system (something `interactive_evolution` does not do by itself), and the fixed points plots are automatically updated when a parameter is changed in the GUI, because it uses the observable `paramvals`.

### Customized animations
It is straightforward to add custom plots and generate extra animations from the interface of the `step` observable returned by [`interactive_evolution`](@ref). In the following example we'll make a video that rotates around some interlaced periodic trajectories, and plot some stuff from them on an extra panel to the right.

```@example DynamicalSystemsInter
using DynamicalSystems, InteractiveDynamics, CairoMakie
using LinearAlgebra: dot, norm

ds = Systems.thomas_cyclical(b = 0.2)
u0s = ([3, 1, 1.], [1, 3, 1.], [1, 1, 3.])
diffeq = (alg = Tsit5(), adaptive = false, dt = 0.05)

fig, obs, step, slidervals = interactive_evolution(
    ds, u0s; tail = 1000, diffeq, add_controls = false, tsidxs = nothing,
    # Some arguments that make final video nicer
    figure = (resolution = (1200, 600),),
)
ax3D = content(fig[1,1][1,1])

# Plot some stuff on a second axis that use `obs`
# Plot distance of trajcetory from symmetry line
ax = Axis(fig[1,1][1,2]; xlabel = "points", ylabel = "distance")
function distance_from_symmetry(u)
    v = SVector(1/√3, 1/√3, 1/√3)
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
        ax3D.azimuth = ax3D.azimuth[] + 2π/2000
    end
end
```
(be careful not to use CairoMakie.jl for producing videos of 3D plots like above)

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

## Interactive Poincaré Surface of Section
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/interactive_psos.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_poincaresos
```

To generate the animation at the start of this section you can run
```julia
using InteractiveDynamics, GLMakie, OrdinaryDiffEq, DynamicalSystems
diffeq = (alg = Vern9(), abstol = 1e-9, reltol = 1e-9)

hh = Systems.henonheiles()

potential(x, y) = 0.5(x^2 + y^2) + (x^2*y - (y^3)/3)
energy(x,y,px,py) = 0.5(px^2 + py^2) + potential(x,y)
const E = energy(get_state(hh)...)

function complete(y, py, x)
    V = potential(x, y)
    Ky = 0.5*(py^2)
    Ky + V ≥ E && error("Point has more energy!")
    px = sqrt(2(E - V - Ky))
    ic = [x, y, px, py]
    return ic
end

plane = (1, 0.0) # first variable crossing 0

# Coloring points using the Lyapunov exponent
function λcolor(u)
    λ = lyapunovs(hh, 4000; u0 = u)[1]
    λmax = 0.1
    return RGBf(0, 0, clamp(λ/λmax, 0, 1))
end

state, scene = interactive_poincaresos(hh, plane, (2, 4), complete;
labels = ("q₂" , "p₂"),  color = λcolor, diffeq...)
```
