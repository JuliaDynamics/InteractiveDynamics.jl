using InteractiveChaos, Observables, Test
using DynamicalSystems

ds = Systems.standardmap()
p_index = 1

ds, pmin, pmax = Systems.standardmap(), 0.6, 1.2

integ = integrator(ds)

for i in 1:2
od, xmin, xmax = InteractiveChaos.minimal_normalized_od(integ, i, p_index, pmin, pmax,
                 100, 100, 100, get_state(ds))

@test xmin ≥ 0
@test xmax ≤ 2π
end

od, xmin, xmax = InteractiveChaos.minimal_normalized_od(integ, 1, p_index, pmin, pmax,
                 100, 100, 100, get_state(ds))

# Now to simulate selecting a rectangle:
rect = Observable((origin = [0., 0], widths = [1., 1.]))
OD = Observable(od)
od0 = copy(od)

on(rect) do r
    pmin, xmin = r.origin
    pmax, xmax = r.origin + r.widths

    OD[] = InteractiveChaos.minimal_normalized_od(
        integ, 1,  p_index, pmin, pmax,
        100, 100, 100, get_state(ds), xmin, xmax
    )
end

# change rectangle:
rect[] = (origin = [0.8, 0.2], widths = [1., 5.0])

@test od0 != OD[]
