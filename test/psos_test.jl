using InteractiveChaos, Observables, Test
using DynamicalSystems

ds = Systems.henonheiles()

potential(x, y) = 0.5(x^2 + y^2) + (x^2*y - (y^3)/3)
energy(x,y,px,py) = 0.5(px^2 + py^2) + potential(x,y)
E = energy(get_state(ds)...)
function complete(y, py, x)
    V = potential(x, y)
    Ky = 0.5*(py^2)
    Ky + V ≥ E && error("Point has more energy!")
    px = sqrt(2(E - V - Ky))
    ic = [x, y, px, py]
    return ic
end

chaotic = get_state(ds)
stable = [0., 0.1, 0.5, 0.]
plane = (1, 0.0)
tf = 1000.0
idxs = SVector{2, Int}(2, 4)
u0 = get_state(ds); D = 4
Ttr = 200.0
rootkw = (xrtol = 1e-6, atol = 1e-6)

integ = integrator(ds, u0)
planecrossing = PlaneCrossing(plane, true)
f = (t) -> planecrossing(integ(t))
i = SVector{2, Int}(idxs)
data = poincaresos(integ, planecrossing, tf, Ttr, i, rootkw)
data0 = copy(data)

# Emulate clicking on the psos
click = Observable([0.0, 0.0])
Data = Observable(data)

on(click) do pos
    x, y = pos; z = plane[2]
    newstate = try
       complete(x, y, z)
    catch err
       @error "Could not get state, got error:" exception=err
       return
    end
    @assert length(newstate) == D

    reinit!(integ, newstate)

    Data[] = poincaresos(integ, planecrossing, tf, Ttr, i, rootkw)
    return data
end

# we click on the psos now
click[] = [0.2, 0.2]

@test Data[] != data0
