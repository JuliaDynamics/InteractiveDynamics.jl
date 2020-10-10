using DynamicalBilliards, InteractiveChaos, Makie

N = 100
colors = :dense
colors = [Makie.RGBAf0(i/N, 0, 1 - i/N, 0.25) for i in 1:N]

# Uncomment any of the following to get the billiard you want:
# bd = billiard_stadium(1.0f0, 1.0f0)
# bd = Billiard(bd..., Disk(SVector(0.5f0, 0.5f0), 0.2f0))
bd = billiard_mushroom(1.0f0, 0.2f0, 1.0f0, 0.0f0; door = false)
# bd = billiard_hexagonal_sinai(0.5f0, 1.0f0)
# bd = billiard_sinai(0.25f0, 1f0, 1f0)
# bd = Billiard(Antidot(Float32[0, 0], 0.5f0, false))
# bd, = billiard_logo(T = Float32)

ps = [MagneticParticle(1, 0.6f0 + 0.0005f0*i, 0, 1f0) for i in 1:N]
ps = [Particle(1, 0.6f0 + 0.0005f0*i, 0) for i in 1:N]
ps = particlebeam(0.8, 0.6, π/4, N, 0.01, nothing, Float32)

interactive_billiard(bd, 1f0, tail = 1000);


# %% also interact with boundary map
interactive_billiard_bmap(bd);

# %% make it a video
billiard_video("billiard.mp4", bd, 1f0; plot_particles=false, framerate = 120);

# %% static plot of boundary map and billiard (several particles, same color)
ps = [randominside(bd) for i in 1:N]
scene, bmapax = billiard_bmap_plot(bd, ps; colors = colors, backgroundcolor = RGBf0(1,1,1))
Makie.save("static_billiard_plot.png", scene)

# %% 3b1b style video:
# Colors of 3b1b
BLUE = "#7BC3DC"
BROWN = "#8D6238"
colors = [BLUE, BROWN]
# Overwrite default color of obstacles to white (to fit with black)
InteractiveChaos.obcolor(::Obstacle) = RGBf0(1,1,1)
bd = billiard_stadium(1.0f0, 1.0f0)
billiard_video(
    "3b1billiard.mp4", bd, 1.0, 0.6, 0;
    frames = 1200, speed = 8, backgroundcolor = :black, colors = colors
)
