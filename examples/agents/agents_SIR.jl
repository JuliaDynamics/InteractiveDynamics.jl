## InteractiveDynamics test area

using Agents, Random, DataFrames
using Agents.Graphs
using Distributions: Poisson, DiscreteNonParametric
using DrWatson: @dict
using LinearAlgebra: diagind
using InteractiveDynamics
using GLMakie
using Statistics
using GraphMakie.NetworkLayout

## Model details

@agent PoorSoul GraphAgent begin
    days_infected::Int  # number of days since is infected
    status::Symbol  # 1: S, 2: I, 3:R
end

function model_initiation(;
    Ns,
    migration_rates,
    β_und,
    β_det,
    infection_period = 30,
    reinfection_probability = 0.05,
    detection_time = 14,
    death_rate = 0.02,
    Is = [zeros(Int, length(Ns) - 1)..., 1],
    seed = 0,
)

    rng = MersenneTwister(seed)
    @assert length(Ns) ==
    length(Is) ==
    length(β_und) ==
    length(β_det) ==
    size(migration_rates, 1) "length of Ns, Is, and B, and number of rows/columns in migration_rates should be the same "
    @assert size(migration_rates, 1) == size(migration_rates, 2) "migration_rates rates should be a square matrix"

    C = length(Ns)
    # normalize migration_rates
    migration_rates_sum = sum(migration_rates, dims = 2)
    for c in 1:C
        migration_rates[c, :] ./= migration_rates_sum[c]
    end

    properties = @dict(
        Ns,
        Is,
        β_und,
        β_det,
        β_det,
        migration_rates,
        infection_period,
        infection_period,
        reinfection_probability,
        detection_time,
        C,
        death_rate
    )
    space = GraphSpace(complete_digraph(C))
    model = ABM(PoorSoul, space; properties, rng)

    # Add initial individuals
    for city in 1:C, n in 1:Ns[city]
        ind = add_agent!(city, model, 0, :S) # Susceptible
    end
    # add infected individuals
    for city in 1:C
        inds = ids_in_position(city, model)
        for n in 1:Is[city]
            agent = model[inds[n]]
            agent.status = :I # Infected
            agent.days_infected = 1
        end
    end
    return model
end

function create_params(;
    C,
    max_travel_rate,
    infection_period = 30,
    reinfection_probability = 0.05,
    detection_time = 14,
    death_rate = 0.02,
    Is = [zeros(Int, C - 1)..., 1],
    seed = 19,
)

    Random.seed!(seed)
    Ns = rand(50:5000, C)
    β_und = rand(0.3:0.02:0.6, C)
    β_det = β_und ./ 10

    Random.seed!(seed)
    migration_rates = zeros(C, C)
    for c in 1:C
        for c2 in 1:C
            migration_rates[c, c2] = (Ns[c] + Ns[c2]) / Ns[c]
        end
    end
    maxM = maximum(migration_rates)
    migration_rates = (migration_rates .* max_travel_rate) ./ maxM
    migration_rates[diagind(migration_rates)] .= 1.0

    params = @dict(
        Ns,
        β_und,
        β_det,
        migration_rates,
        infection_period,
        reinfection_probability,
        detection_time,
        death_rate,
        Is
    )

    return params
end

## Stepping

function agent_step!(agent, model)
    migrate!(agent, model)
    transmit!(agent, model)
    update!(agent, model)
    recover_or_die!(agent, model)
end

function migrate!(agent, model)
    pid = agent.pos
    d = DiscreteNonParametric(1:(model.C), model.migration_rates[pid, :])
    m = rand(model.rng, d)
    if m ≠ pid
        move_agent!(agent, m, model)
    end
end

function transmit!(agent, model)
    agent.status == :S && return
    rate = if agent.days_infected < model.detection_time
        model.β_und[agent.pos]
    else
        model.β_det[agent.pos]
    end

    d = Poisson(rate)
    n = rand(model.rng, d)
    n == 0 && return

    for contactID in ids_in_position(agent, model)
        contact = model[contactID]
        if contact.status == :S ||
           (contact.status == :R && rand(model.rng) ≤ model.reinfection_probability)
            contact.status = :I
            n -= 1
            n == 0 && return
        end
    end
end

update!(agent, model) = agent.status == :I && (agent.days_infected += 1)

function recover_or_die!(agent, model)
    if agent.days_infected ≥ model.infection_period
        if rand(model.rng) ≤ model.death_rate
            kill_agent!(agent, model)
        else
            agent.status = :R
            agent.days_infected = 0
        end
    end
end

## init model

params = create_params(C = 8, max_travel_rate = 0.01)
model = model_initiation(; params...)
model_step! = dummystep

## abmplot

fig, ax, abmobs = abmplot(model; graphplotkwargs = (; layout = Shell(), arrow_show = false))
fig

## abmplot with abmobs instead of model
abmobs = ABMObservable(model_initiation(; params...); agent_step!)
fig, ax, abmobs = abmplot(abmobs; 
    graphplotkwargs = (; layout = Shell(), arrow_show = false))
fig

## abmexploration

fig, abmobs = abmexploration(model_initiation(; params...); 
    agent_step!, graphplotkwargs = (; layout = Shell(), arrow_show = false))
fig

## dynamic sizes, colors, markers...

city_size(model, idx) = 20 + 0.005 * length(model.space.stored_ids[idx])

function city_color(model, idx)
    agents_here = count(a.pos == idx for a in allagents(model))
    infected = count((a.pos == idx && a.status == :I) for a in allagents(model))
    recovered = count((a.pos == idx && a.status == :R) for a in allagents(model))
    return RGBf(infected / agents_here, recovered / agents_here, 0)
end

edge_color(model) = [rand([:red, :orange, :yellow, :green, :blue, :purple]) for _ in 1:model.space.graph.ne]

edge_width(model) = [4 * rand(model.rng) for _ in 1:model.space.graph.ne]

graphplotkwargs = (
    layout = Shell(),
    arrow_show = false,
    edge_color = edge_color,
    edge_width = edge_width,
)

fig, ax, abmobs = abmplot(model_initiation(; params...);  
    agent_step!, as = city_size, ac = city_color, graphplotkwargs)
fig

## abmexploration

population(model) = length(allids(model))
count_infected(model) = count(a -> a.status == :I, allagents(model))
count_recovered(model) = count(a -> a.status == :R, allagents(model))
exploration_params = Dict(
    :infection_period => 14:1:30,
    :reinfection_probability => 0.0:0.01:0.1
)

fig, abmobs = abmexploration(model_initiation(; params...); 
    agent_step!, params = exploration_params, 
    mdata = [population, count_infected, count_recovered], 
    as = city_size, ac = city_color, graphplotkwargs)
fig

## abmvideo

model = model_initiation(; params...)
abmvideo("testGraphSpace/abmvideo.mp4", model, agent_step!, model_step!;
    framerate = 10, frames = 100, title = "Social Distancing",
    as = city_size, ac = city_color, graphplotkwargs)
