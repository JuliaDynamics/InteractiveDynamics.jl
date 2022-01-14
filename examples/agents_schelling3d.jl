using Agents

mutable struct SchellingAgent <: AbstractAgent
    id::Int             # The identifier number of the agent
    pos::NTuple{3, Int} # The x, y, z location of the agent on a 3D grid
    mood::Bool          # whether the agent is happy in its position. (true = happy)
    group::Int          # The group of the agent, determines mood as it interacts with neighbors
end

using Random # for reproducibility
function initialize(; numagents = 520, griddims = (20, 20, 20), min_to_be_happy = 2, seed = 125)
    space = GridSpace(griddims, periodic = false)
    properties = Dict(:min_to_be_happy => min_to_be_happy)
    rng = Random.MersenneTwister(seed)
    model = ABM(
        SchellingAgent, space;
        properties, rng, scheduler = Schedulers.randomly
    )
    for n in 1:numagents
        agent = SchellingAgent(n, (1, 1, 1), false, n < numagents / 2 ? 1 : 2)
        add_agent_single!(agent, model)
    end
    return model
end

function agent_step!(agent, model)
    minhappy = model.min_to_be_happy
    count_neighbors_same_group = 0
    for neighbor in nearby_agents(agent, model)
        if agent.group == neighbor.group
            count_neighbors_same_group += 1
        end
    end
    if count_neighbors_same_group ≥ minhappy
        agent.mood = true
    else
        move_agent_single!(agent, model)
    end
    return
end

using InteractiveDynamics, GLMakie

model = initialize()
ac(agent) = (:red, :blue)[agent.group]
am(agent) = (:circle, :rect)[agent.group]
fig, step = abm_play(model, agent_step!, dummystep; ac, am, as = 5000)
