using InteractiveDynamics, GLMakie

A = rand(5, 5)
A[1,1] = 0
A[5,5] = 1
A[3,3] = 0.5


fig = Figure(resolution=(2000, 1000))
display(fig)

ax, hm = heatmap(fig[1,1], A; colormap = JULIADYNAMICS_CMAP, colorrange=(0,1))
Colorbar(fig[1, 2], hm)
ax, hm = heatmap(fig[1,3], A; colormap = JULIADYNAMICS_CMAP_DIVERGING, colorrange=(0,1))
Colorbar(fig[1, 4], hm)
