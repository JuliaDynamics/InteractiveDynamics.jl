using DynamicalBilliards, InteractiveDynamics, GLMakie

N = 100
colors = :dense
colors = []
colors = [GLMakie.RGBAf(i/N, 0, 1 - i/N, 0.25) for i in 1:N]

# Uncomment any of the following to get the billiard you want:
bd = billiard_stadium()
# bd = billiard_mushroom()
# bd = billiard_hexagonal_sinai(0.5, 1.0)
# bd = billiard_sinai(0.25f0, 1f0, 1f0)
# bd = Billiard(Antidot(Float32[0, 0], 0.5f0, false))
# bd, = billiard_logo(T = Float32)

# ps = [MagneticParticle(1, 0.6 + 0.0005*i, 0, 1) for i in 1:N]
# ps = [Particle(1, 0.6 + 0.00005*i, 0) for i in 1:N]
ps = particlebeam(0.8, 0.6, π/4, N, 0.01, nothing)

fig, phs, chs = bdplot_interactive(bd, ps; tail_length = 1000);
display(fig)
