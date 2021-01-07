using GLMakie, DynamicalSystems, InteractiveChaos
using OrdinaryDiffEq

ds = Systems.henonheiles()
diffeq = (alg = Vern9(),)
u0s = [
    [0.0, -0.25, 0.42081, 0.0],
    [0.0, 0.1, 0.5, 0.0],
    [0.0, -0.31596, 0.354461, 0.0591255]
]
trs = [trajectory(ds, 10000, u0; diffeq...)[:, SVector(1,2,3)] for u0 ∈ u0s]
for i in 2:length(u0s)
    append!(trs[1], trs[i])
end

# Inputs:
j = 2 # the dimension of the plane
tr = trs[1]

brainscan_poincaresos(tr, j)
