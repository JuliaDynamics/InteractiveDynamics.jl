using Agents
using GLMakie
using InteractiveDynamics

# Define model
@agent Bird ContinuousAgent{2} begin
    speed::Float64
    cohere_factor::Float64
    separation::Float64
    separate_factor::Float64
    match_factor::Float64
    visual_distance::Float64
end

function init_flocking(;
    n_birds = 100,
    speed = 1.0,
    cohere_factor = 0.25,
    separation = 4.0,
    separate_factor = 0.25,
    match_factor = 0.01,
    visual_distance = 5.0,
    extent = (100, 100),
    seed = 42,
)
    space2d = ContinuousSpace(extent; spacing = visual_distance/1.5)
    rng = Random.MersenneTwister(seed)
    birds = [Bird(
        i,
        Tuple(rand(rng, 2) .* extent),
        Tuple(rand(rng, 2) * 2 .- 1),
        speed,
        cohere_factor,
        separation,
        separate_factor,
        match_factor,
        visual_distance,
    ) for i in 1:n_birds]

    model = FixedMassABM(birds, space2d; rng, scheduler = Schedulers.Randomly())
    return model
end

function flocking_agent_step!(bird, model)
    neighbor_ids = nearby_ids(bird, model, bird.visual_distance)
    N = 0
    match = separate = cohere = (0.0, 0.0)
    for id in neighbor_ids
        N += 1
        neighbor = model[id].pos
        heading = neighbor .- bird.pos

        cohere = cohere .+ heading
        if euclidean_distance(bird.pos, neighbor, model) < bird.separation
            separate = separate .- heading
        end
        match = match .+ model[id].vel
    end
    N = max(N, 1)
    cohere = cohere ./ N .* bird.cohere_factor
    separate = separate ./ N .* bird.separate_factor
    match = match ./ N .* bird.match_factor
    bird.vel = (bird.vel .+ cohere .+ separate .+ match) ./ 2
    bird.vel = bird.vel ./ norm(bird.vel)
    move_agent!(bird, model, bird.speed)
end

model = init_flocking()

const bird_polygon = Polygon(Point2f[(-0.5, -0.5), (1, 0), (-0.5, 0.5)])
function bird_marker(b::Bird)
    φ = atan(b.vel[2], b.vel[1]) #+ π/2 + π
    scale(rotate2D(bird_polygon, φ), 2)
end

# simple plot
fig, ax, abmobs = abmplot(model; am = bird_marker)
fig

# interactive app
fig, ax, abmobs = abmplot(model;
    axis = (; title = "Flocking"),
    agent_step! = flocking_agent_step!,
    model_step! = flocking_model_step!,
    am = bird_marker,
)
fig
