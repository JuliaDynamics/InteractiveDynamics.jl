using InteractiveDynamics
using DynamicalSystems, GLMakie
using OrdinaryDiffEq

# Lorenz
ds = Systems.lorenz()
diffeq = (alg = Tsit5(), adaptive = false, dt = 0.01)

u1 = [10,20,40.0]
u2 = [10,20,40.0 + 1e-3]
u3 = [20,10,40.0]
u0s = [u1, u2, u3]

idxs = (1, 2, 3)

figure, obs = interactive_evolution(
    ds, u0s; idxs, tail = 1000, diffeq
)

# %% Lorenz with parameters
ps = Dict(
    1 => 1:0.1:30,
    2 => 10:0.1:100,
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
    Point3f(0,0,0),
    Point3f(sqrt(β*(ρ-1)), sqrt(β*(ρ-1)), ρ-1),
    Point3f(-sqrt(β*(ρ-1)), -sqrt(β*(ρ-1)), ρ-1),
]

fpobs = lift(lorenzfp, slidervals[2], slidervals[3])
ax = content(figure[1,1])
scatter!(ax, fpobs; markersize = 5000, marker = :diamond)

# end

# %% towel
ds = Systems.towel()
u0s = [0.1ones(3) .+ 1e-3rand(3) for _ in 1:3]
idxs = (1, 2, 3)

figure, obs = interactive_evolution(
    ds, u0s; idxs, tail = 10000,
)

# %% SM
ds = Systems.standardmap()
u0s = [[0.1, 0.1], [2.5, 0.4], [1.88, 3.25]]
lims = ((0, 2π), (0, 2π))

figure, obs = interactive_evolution(
    ds, u0s; tail = 100000, lims
)

# %% Henon helies

ds = Systems.henonheiles()

u0s = [[0.0, -0.25, 0.42081, 0.0],
[0.0, 0.1, 0.5, 0.0],
[0.0, -0.31596, 0.354461, 0.0591255]]

diffeq = (alg = Vern9(), dt = 0.01, adaptive = false)
idxs = (1, 2, 4)
colors = Makie.to_color.(["#233B43", "#499cbf", "#E84646"])

figure, obs = interactive_evolution(
    ds, u0s; idxs, tail = 10000, colors, diffeq
)
# main.scene[Axis][:names, :axisnames] = ("q₁", "q₂", "p₂")
