using InteractiveChaos
using DynamicalSystems, GLMakie
using OrdinaryDiffEq

# Lorenz
ds = Systems.lorenz()

u1 = [10,20,40.0]
u2 = [10,20,40.0 + 1e-3]
u3 = [20,10,40.0]
u0s = [u1, u2, u3]

idxs = (1, 2, 3)
diffeq = (alg = Tsit5(), dtmax = 0.01)

figure, main, obs = interactive_evolution(
    ds, u0s; idxs, tail = 1000, diffeq
)

# %% Lorenz with timeseries
ds = Systems.lorenz()

u1 = [10,20,40.0]
u2 = [10,20,40.0 + 1e-3]
u3 = [20,10,40.0]
u0s = [u1, u2, u3]

idxs = (1, 2, 3)
diffeq = (alg = Tsit5(), dtmax = 0.01)

figure, obs = interactive_evolution_timeseries(
    ds, u0s; idxs, tail = 1000, diffeq
)

# %% towel
ds = Systems.towel()
u0s = [0.1ones(3) .+ 1e-3rand(3) for _ in 1:3]
idxs = (1, 2, 3)

figure, main, obs = interactive_evolution(
    ds, u0s; idxs, tail = 10000,
)

# %% SM
ds = Systems.standardmap()
u0s = [[0.1, 0.1], [2.5, 0.4], [1.88, 3.25]]
lims = ((0, 2π), (0, 2π))

figure, main, obs = interactive_evolution(
    ds, u0s; tail = 100000, lims
)

# %% Henon helies

ds = Systems.henonheiles()

u0s = [[0.0, -0.25, 0.42081, 0.0],
[0.0, 0.1, 0.5, 0.0],
[0.0, -0.31596, 0.354461, 0.0591255]]

diffeq = (alg = Vern9(), dtmax = 0.01)
idxs = (1, 2, 4)
colors = AbstractPlotting.to_color.(["#233B43", "#499cbf", "#E84646"])

figure, main, obs = interactive_evolution(
    ds, u0s; idxs, tail = 10000, colors, diffeq
)
# main.scene[Axis][:names, :axisnames] = ("q₁", "q₂", "p₂")
