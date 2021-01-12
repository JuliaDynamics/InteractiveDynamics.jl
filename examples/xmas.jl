using DynamicalBilliards, InteractiveChaos, GLMakie

SV = SVector{2, Float32}
w = 0.4 # stump width
points_right = [
    SV(w, 0),
    SV(w, w),
    SV(2.0, w),
    SV(w, 1.5),
    SV(1.5, 1.5),
    SV(w, 2.25),
    SV(1.0, 2.25),
]
summit = SV(0.0, 3.0)
points_left = reverse!([SV(-p[1], p[2]) for p in points_right])
tree_points = [points_right..., summit, points_left...]

tree_billiard = billiard_vertices(tree_points)

ps = particlebeam(0.0, 0.1, π/4, 1, 0.01, nothing, Float32)

interactive_billiard(tree_billiard, ps; dt = 0.1)
