using InteractiveChaos
using DynamicalSystems, Makie
using OrdinaryDiffEq

# Lorenz
ds = Systems.lorenz()

u1 = [10,20,40.0]
u2 = [10,20,40.0 + 1e-3]
u3 = [20,10,40.0]
u0s = [u1, u2, u3]

diffeq = (alg = Tsit5(), dtmax = 0.01)

somescene, someobs = interactive_evolution(
    ds, u0s; idxs = SVector(1, 2, 3), tail = 10000, diffeq
)


# %% towel
ds = Systems.towel()
u1 = rand(3)
u2 = rand(3)
u3 = rand(3)
u0s = [u1, u2, u3]

somescene, someobs = interactive_evolution(
    ds, u0s; idxs = SVector(1, 2, 3), tail = 100000,
)

# %% SM
ds = Systems.standardmap()
u0s = [[0.1, 0.1], [2.5, 0.4], [1.88, 3.25]]
lims = ((0, 2π), (0, 2π))

somescene, someobs = interactive_evolution(
    ds, u0s; tail = 100000, lims
)

# %% Henon helies

ds = Systems.henonheiles()

u0s = [[0.0, -0.25, 0.42081, 0.0],
[0.0, 0.1, 0.5, 0.0],
[0.0, -0.31596, 0.354461, 0.0591255]]

diffeq = (alg = Vern9(), dtmax = 0.01)

lims = ((-1, 1), (-1, 1), (-1, 1))
idxs = SVector(1, 3, 4)

somescene, someobs = interactive_evolution(
    ds, u0s; idxs, tail = 10000, diffeq
)
