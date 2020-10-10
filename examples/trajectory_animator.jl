using InteractiveChaos
using DynamicalSystems, Makie

# Lorenz
ds = Systems.lorenz()

u1 = [10,20,40.0]
u2 = [10,20,40.0 + 1e-6]
u3 = [20,10,40.0]
u0s = [u1, u2, u3]
lims = ((-25, 25), (-25, 25), (0, 40))

somescene, someobs = interactive_evolution(
    ds, u0s; idxs = SVector(1, 2, 3), dtmax = 0.001, tail = 1000,
    lims = lims
)


# %% towel
ds = Systems.towel()
u1 = rand(3)
u2 = rand(3)
u3 = rand(3)
u0s = [u1, u2, u3]
lims = ((-1, 1), (-0.1, 0.1), (-1, 2))

somescene, someobs = interactive_evolution(
    ds, u0s; idxs = SVector(1, 2, 3), tail = 100000,
    lims = lims
)

# %% Henon
