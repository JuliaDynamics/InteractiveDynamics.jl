using Agents, Random
using Makie
using InteractiveChaos

cd(@__DIR__)

mutable struct PoorSoul <: AbstractAgent
    id::Int
    pos::NTuple{2,Float64}
    vel::NTuple{2,Float64}
    mass::Float64
    days_infected::Int  # number of days since is infected
    status::Symbol  # :S, :I or :R
    β::Float64
end

const steps_per_day = 24

using DrWatson: @dict
function sir_initiation(;
    infection_period = 30 * steps_per_day,
    detection_time = 14 * steps_per_day,
    reinfection_probability = 0.05,
    isolated = 0.0, # in percentage
    interaction_radius = 0.012,
    dt = 1.0,
    speed = 0.002,
    death_rate = 0.044, # from website of WHO
    N = 1000,
    initial_infected = 5,
    seed = 42,
    βmin = 0.4,
    βmax = 0.8,
)

    properties = @dict(
        infection_period,
        reinfection_probability,
        detection_time,
        death_rate,
        interaction_radius,
        dt,
    )
    space = ContinuousSpace(2)
    model = ABM(PoorSoul, space, properties = properties)

    ## Add initial individuals
    Random.seed!(seed)
    for ind in 1:N
        pos = Tuple(rand(2))
        status = ind ≤ N - initial_infected ? :S : :I
        isisolated = ind ≤ isolated * N
        mass = isisolated ? Inf : 1.0
        vel = isisolated ? (0.0, 0.0) : sincos(2π * rand()) .* speed

        ## very high transmission probability
        ## we are modelling close encounters after all
        β = (βmax - βmin) * rand() + βmin
        add_agent!(pos, model, vel, mass, 0, status, β)
    end

    Agents.index!(model)
    return model
end

model = sir_initiation()


function transmit!(a1, a2, rp)
    ## for transmission, only 1 can have the disease (otherwise nothing happens)
    count(a.status == :I for a in (a1, a2)) ≠ 1 && return
    infected, healthy = a1.status == :I ? (a1, a2) : (a2, a1)

    rand() > infected.β && return

    if healthy.status == :R
        rand() > rp && return
    end
    healthy.status = :I
end

function model_step!(model)
    r = model.interaction_radius
    for (a1, a2) in interacting_pairs(model, r, :nearest)
        transmit!(a1, a2, model.reinfection_probability)
        elastic_collision!(a1, a2, :mass)
    end
end

function agent_step!(agent, model)
    move_agent!(agent, model, model.dt)
    update!(agent)
    recover_or_die!(agent, model)
end

update!(agent) = agent.status == :I && (agent.days_infected += 1)

function recover_or_die!(agent, model)
    if agent.days_infected ≥ model.infection_period
        if rand() ≤ model.death_rate
            kill_agent!(agent, model)
        else
            agent.status = :R
            agent.days_infected = 0
        end
    end
end

infected(x) = count(i == :I for i in x)
recovered(x) = count(i == :R for i in x)
adata = [(:status, infected), (:status, recovered)]
mdata = [nagents]



sir_colors(a) = a.status == :S ? "#2b2b33" : a.status == :I ? "#bf2642" : "#338c54"
sir_sizes(a) = 0.01*randn()
sir_sizes(a) = 0.005*(mod1(a.id, 3)+1)

# sir_shape(a) = rand(('🐑', '🐺', '🌳'))
# sir_shape(a) = rand(('😹', '🐺', '🌳'))
# sir_shape(a) = rand(('π', '😹', '⚃', '◑', '▼'))
# sir_shape(a) = rand((:diamond, :circle))
sir_shape(a) = a.status == :S ? :circle : a.status == :I ? :diamond : :rect

# function sir_shape(b)
#     φ = atan(b.vel[2], b.vel[1])
#     xs = [(i ∈ (0, 3) ? 2 : 1)*cos(i*2π/3 + φ) for i in 0:3]
#     ys = [(i ∈ (0, 3) ? 2 : 1)*sin(i*2π/3 + φ) for i in 0:3]
#     Shape(xs, ys)
# end

params = Dict(:death_rate => 0.02:0.001:1.0,
:reinfection_probability => 0:0.01:1.0,
:dt => 0.01:0.01:2.0)

when = (model, s) -> s % 50 == 0

p1 = interactive_abm(model, agent_step!, model_step!, params;
ac = sir_colors, as = sir_sizes, am = sir_shape, when = when)
