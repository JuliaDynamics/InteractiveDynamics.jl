using Agents

@agent Particle ContinuousAgent{3} begin
    radius::Float64
end

function initialize_model(; 
    N = 100, space_extents = (10.0, 10.0, 10.0),
    )
    space = ContinuousSpace(space_extents, 1.0; periodic = true)
    model = ABM(Particle, space)
    for i in 1:N
        particle = Particle(i, random_position(model), (0.0, 0.0, 0.0), rand())
        add_agent_pos!(particle, model)
    end
    return model
end

model = initialize_model()

using InteractiveDynamics, GLMakie

as(agent) = 0.1agent.radius + 0.1
fig, step = abm_plot(model; as)
fig