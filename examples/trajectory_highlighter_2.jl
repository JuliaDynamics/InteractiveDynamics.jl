using InteractiveChaos, Makie
ds = Systems.qbh()
# Grid of initial conditions at given energy:
energy(x,y,px,py) = 0.5(px^2 + py^2) + potential(x,y)
potential(x, y) = 0.5(x^2 + y^2) + 0.55/(√2)*x*(3y^2 - x) + 0.1(x^2 + y^2)^2
function generate_ics(E, n)
    ys = range(-4, stop = 4, length = n)
    pys = range(-10, stop = 10, length = n)
    ics = Vector{Vector{Float64}}()
    for y in ys
        V = potential(0.0, y)
        V ≥ E && continue
        for py in pys
            Ky = 0.5*(py^2)
            Ky + V ≥ E && continue
            px = sqrt(2(E - V - Ky))
            ic = [0.0, y, px, py]
            push!(ics, [px, py, 0., y])
        end
    end
    return ics
end

density = 18
tpsos = 1000.0
tλ = 5000
ttr = 200.0
ics = generate_ics(120.0, density)

tinteg = tangent_integrator(ds, 1)
λ = Float64[]; psos = Dataset{2, Float64}[]
trs = Dataset{3, Float64}[]

@time for u in ics
    # compute Lyapunov exponent (using advanced usage)
    reinit!(tinteg, u, orthonormal(4,1))
    push!(λ, lyapunovs(tinteg, tλ, 1, 1.0)[1])
    push!(psos, poincaresos(ds, (3, 0.0), tpsos; u0 = u, idxs = [4, 2]))
    tr = trajectory(ds, ttr, u)[:, SVector(3, 4, 2)]
    push!(trs, tr)
end
# %%
trajectory_highlighter(psos, λ;
markersize = 0.1, nbins = 10, α = 0.01, hname = "λ")

# trajectory_highlighter(trs[1:(length(trs)÷10):end], λ[1:(length(trs)÷10):end];
# nbins = 10, α = 0.001, linewidth = 2.0, hname = "λ",
# transparency = true)
