using DynamicalBilliards, InteractiveChaos, Makie

N = 100
colors = :dense
colors = [Makie.RGBAf0(i/N, 0, 1 - i/N, 0.25) for i in 1:N]
bd = billiard_stadium(1.0f0, 1.0f0)
# bd = Billiard(bd..., Disk(SVector(0.5f0, 0.5f0), 0.2f0))
bd = billiard_mushroom(1.0f0, 0.2f0, 1.0f0, 0.0f0; door = false)
# bd = billiard_hexagonal_sinai(0.5f0, 1.0f0)
# bd = billiard_sinai(0.25f0, 1f0, 1f0)

ps = [MagneticParticle(1, 0.6f0 + 0.0005f0*i, 0, 1f0) for i in 1:N]
ps = [Particle(1, 0.6f0 + 0.0005f0*i, 0) for i in 1:N]
ps = particlebeam(0.8, 0.6, π/4, 100, 0.01, nothing, Float32)

scene, layout, allparobs = interactive_billiard(bd, 1f0)


# %%
scene, layout, parobs = interactive_billiard_bmap(bd)


scene, layout = layoutscene()
ax = layout[1, 1] = LAxis(scene)
second_xaxis = MakieLayout.LineAxis(scene,
    endpoints = lift(MakieLayout.topline, ax.layoutobservables.computedbbox),
    limits = [0, 1], flipped = true, ticklabelalign = (:center, :bottom),
    # these are just because I forgot to set defaults...
    spinecolor = :black, labelfont = "Dejavu", ticklabelfont = "Dejavu",
    spinevisible = true)
scene
