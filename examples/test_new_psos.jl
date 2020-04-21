using InteractiveChaos, Makie, OrdinaryDiffEq, DynamicalSystems
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

# %%
ds = hh
D = dimension(ds)
idxs = (2, 4)
direction = -1
Ttr = (0.0, 1000.0)
tfinal = (1000.0, 10.0^4)
rootkw = (xrtol = 1e-6, atol = 1e-6)
color = randomcolor
scatterkwargs = ()
labels = ("u₁" , "u₂")
ms = 10

@assert typeof(plane) <: Tuple
@assert length(idxs) == 2
@assert eltype(idxs) == Int
@assert plane[1] ∉ idxs
u0 = get_state(ds)

# This is the low-level call of poincaresos:
ChaosTools._check_plane(plane, D)
integ = integrator(ds, u0; diffeq...)
planecrossing = PlaneCrossing(plane, direction > 0)
i = SVector{2, Int}(idxs)

scene, layout = layoutscene(resolution = (1000, 800))

T_slider, Ttr_slider = _add_psos_controls!(scene, layout, tfinal, Ttr)
ax = layout[0, :] = LAxis(scene)


# Initial Section
data = poincaresos(integ, planecrossing, T_slider[], Ttr_slider[], i, rootkw)
length(data) == 0 && error(ChaosTools.PSOS_ERROR)

display(scene)
