using Agents
using GLMakie
using InteractiveDynamics
using LinearAlgebra: norm
using Random

# Create flocking model
@agent Bird ContinuousAgent{2} begin
    speed::Float64
    cohere_factor::Float64
    separation::Float64
    separate_factor::Float64
    match_factor::Float64
    visual_distance::Float64
end

function flocking(;
    n_birds = 100,
    speed = 1.0,
    cohere_factor = 0.25,
    separation = 4.0,
    separate_factor = 0.25,
    match_factor = 0.01,
    visual_distance = 5.0,
    extent = (100, 100),
    spacing = visual_distance / 1.5,
    spatial_field_size = (20, 20),
)
    space2d = ContinuousSpace(extent; spacing)
    properties = (spatial_field = rand(spatial_field_size...),)
    model = ABM(Bird, space2d; properties, scheduler = Schedulers.Randomly())
    for _ in 1:n_birds
        vel = Tuple(rand(model.rng, 2) * 2 .- 1)
        add_agent!(
            model,
            vel,
            speed,
            cohere_factor,
            separation,
            separate_factor,
            match_factor,
            visual_distance,
        )
    end
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

function flocking_model_step!(model)
    Random.shuffle!(model.spatial_field)
end

model = flocking()

# %% plot
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

# %% Test plot with a heatmap in continuous space
fig, ax, abmobs = abmplot(model;
    axis = (; title = "Flocking"),
    agent_step! = flocking_agent_step!,
    model_step! = flocking_model_step!,
    am = bird_marker,
    heatarray = :spatial_field,
)
fig