using InteractiveChaos, Makie

N = 100
sim = [rand(50,50) for i=1:N]
vals = rand(N)

# %%


poincare_explorer(sim, vals)
