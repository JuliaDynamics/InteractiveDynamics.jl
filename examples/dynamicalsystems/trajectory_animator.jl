using InteractiveDynamics
using DynamicalSystems, GLMakie
using OrdinaryDiffEq

F, G, a, b = 6.886, 1.347, 0.255, 4.0
ds = Systems.lorenz84(; F, G, a, b)
diffeq = (alg = Tsit5(), adaptive = false, dt = 0.01)

u1 = [0.1, 0.1, 0.1] # periodic
u2 = u1 .+ 1e-3     # fixed point
u3 = [-1.5, 1.2, 1.3] .+ 1e-9 # chaotic
u4 = [-1.5, 1.2, 1.3] .+ 21e-9 # chaotic 2
u0s = [u1, u2, u3, u4]

interactive_evolution(
    ds, u0s; tail = 1000, diffeq, fade = true,
    tsidxs = [1,2],
    # tsidxs = nothing, # comment/uncomment this line to remove timeseries
)

# %% Lorenz63 with parameters and additional plotted elements
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

idxs = [1,2,3]
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
scatter!(ax, fpobs; markersize = 5000, marker = :diamond, color = :black)

# %% Custom animation
using DynamicalSystems, InteractiveDynamics, GLMakie
using OrdinaryDiffEq: Tsit5
using LinearAlgebra: dot, norm

ds = Systems.thomas_cyclical(b = 0.2)
u0s = ([3, 1, 1.], [1, 3, 1.], [1, 1, 3.])
diffeq = (alg = Tsit5(), adaptive = false, dt = 0.05)

fig, obs, step, = interactive_evolution(
    ds, u0s; tail = 1000, diffeq, add_controls = false, tsidxs = nothing,
    idxs = [1, 2, 3],
    figure = (resolution = (1200, 600),),
)
axss = content(fig[1,1][1,1])
axss.title = "State space (projected)"

# Plot some stuff on a second axis that use `obs`
# Plot distance of trajcetory from symmetry line
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

record(fig, "thomas_cyclical.mp4"; framerate = 60) do io
    for i in 1:720
        recordframe!(io)
        # Step multiple times per frame for "faster" animation
        for j in 1:5; step[] = 0; end
        if axss isa Axis3
            axss.azimuth = axss.azimuth[] + 2π/2000
        end
    end
end


# %% towel
ds = Systems.towel()
u0s = [0.1ones(3) .+ 1e-3rand(3) for _ in 1:3]

figure, obs = interactive_evolution(
    ds, u0s; tail = 10000,
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
