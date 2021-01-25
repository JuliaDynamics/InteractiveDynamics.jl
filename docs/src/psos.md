# Interactive Poincaré Surface of Section
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/interactive_psos.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_poincaresos
```

---

To generate the video at the start of this page you can run
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

# %% Coloring points using the Lyapunov exponent
function λcolor(u)
    λ = lyapunovs(hh, 4000; u0 = u)[1]
    λmax = 0.1
    return RGBf0(0, 0, clamp(λ/λmax, 0, 1))
end

state, scene = interactive_poincaresos(hh, plane, (2, 4), complete;
labels = ("q₂" , "p₂"),  color = λcolor, diffeq...)
```
