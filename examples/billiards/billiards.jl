using DynamicalBilliards, InteractiveDynamics, GLMakie

N = 100
colors = :dense
colors = [GLMakie.RGBAf(i/N, 0, 1 - i/N, 0.25) for i in 1:N]

# Uncomment any of the following to get the billiard you want:
# bd = billiard_stadium()
# bd = billiard_mushroom()
# bd = billiard_hexagonal_sinai(0.5, 1.0)
# bd = billiard_sinai(0.25f0, 1f0, 1f0)
# bd = Billiard(Antidot(Float32[0, 0], 0.5f0, false))
bd, = billiard_logo(T = Float32)

# ps = [MagneticParticle(1, 0.6 + 0.0005*i, 0, 1) for i in 1:N]
# ps = [Particle(1, 0.6 + 0.00005*i, 0) for i in 1:N]
ps = particlebeam(randominside_xyφ(bd)..., N, 0.01, nothing)

# Interact a bit
fig, phs, chs = bdplot_interactive(bd, ps; tail_length = 1000);
display(fig)

# %% Boundary map



# %% Add another plot: timeseries of distance of first two particles:
fig, phs, chs = bdplot_interactive(bd, ps; tail_length = 1000, playback_controls=false);
display(fig)
ax = Axis(fig[2,1])
rowsize!(fig.layout, 1, Auto(2))
df(phs) = sqrt(sum(phs[1].p.pos .- phs[2].p.pos).^2)
t = Observable([0.0])
d = Observable([df(phs[])])
on(phs) do phs
    push!(t[], phs[1].T)
    push!(d[], df(phs))
    notify.((t, d))
    autolimits!(ax)
end

lines!(ax, t, d)

# You can now use this loop to make an animation (using `record`)
for i in 1:10
    bdplot_animstep!(phs, chs, bd, 0.001; update = false)
end
bdplot_animstep!(phs, chs, bd, 0.001; update = true)


# %%