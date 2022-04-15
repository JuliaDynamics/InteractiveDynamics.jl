using Agents
using Statistics: mean
import StatsBase
using Random


mutable struct Daisy <: AbstractAgent
    id::Int
    pos::Dims{2}
    breed::Symbol
    age::Int
    albedo::Float64 # 0-1 fraction
end

DaisyWorld = ABM{<:GridSpace, Daisy};

function update_surface_temperature!(pos, model::DaisyWorld)
    ids = ids_in_position(pos, model)
    absorbed_luminosity = if isempty(ids) # no daisy
        ## Set luminosity via surface albedo
        (1 - model.surface_albedo) * model.solar_luminosity
    else
        ## Set luminosity via daisy albedo
        (1 - model[ids[1]].albedo) * model.solar_luminosity
    end
    ## We expect local heating to be 80 ᵒC for an absorbed luminosity of 1,
    ## approximately 30 for 0.5 and approximately -273 for 0.01.
    local_heating = absorbed_luminosity > 0 ? 72 * log(absorbed_luminosity) + 80 : 80
    ## Surface temperature is the average of the current temperature and local heating.
    model.temperature[pos...] = (model.temperature[pos...] + local_heating) / 2
end

function diffuse_temperature!(pos, model::DaisyWorld)
    ratio = get(model.properties, :ratio, 0.5) # diffusion ratio
    npos = nearby_positions(pos, model)
    model.temperature[pos...] =
        (1 - ratio) * model.temperature[pos...] +
        ## Each neighbor is giving up 1/8 of the diffused
        ## amount to each of *its* neighbors
        sum(model.temperature[p...] for p in npos) * 0.125 * ratio
end

function propagate_daisy!(pos, model::DaisyWorld)
    ids = ids_in_position(pos, model)
    if !isempty(ids)
        daisy = model[ids[1]]
        temperature = model.temperature[pos...]
        ## Set optimum growth rate to 22.5 ᵒC, with bounds of [5, 40]
        seed_threshold = (0.1457 * temperature - 0.0032 * temperature^2) - 0.6443
        if rand(model.rng) < seed_threshold
            ## Collect all adjacent position that have no daisies
            empty_neighbors = Tuple{Int,Int}[]
            neighbors = nearby_positions(pos, model)
            for n in neighbors
                if isempty(ids_in_position(n, model))
                    push!(empty_neighbors, n)
                end
            end
            if !isempty(empty_neighbors)
                ## Seed a new daisy in one of those position
                seeding_place = rand(model.rng, empty_neighbors)
                add_agent!(seeding_place, model, daisy.breed, 0, daisy.albedo)
            end
        end
    end
end

function daisy_step!(agent::Daisy, model::DaisyWorld)
    agent.age += 1
    agent.age >= model.max_age && kill_agent!(agent, model)
end

function daisyworld_step!(model)
    for p in positions(model)
        update_surface_temperature!(p, model)
        diffuse_temperature!(p, model)
        propagate_daisy!(p, model)
    end
    model.tick += 1
    solar_activity!(model)
end

function solar_activity!(model::DaisyWorld)
    if model.scenario == :ramp
        if model.tick > 200 && model.tick <= 400
            model.solar_luminosity += model.solar_change
        end
        if model.tick > 500 && model.tick <= 750
            model.solar_luminosity -= model.solar_change / 2
        end
    elseif model.scenario == :change
        model.solar_luminosity += model.solar_change
    end
end

function daisyworld(;
    griddims = (30, 30),
    max_age = 25,
    init_white = 0.2, # % cover of the world surface of white breed
    init_black = 0.2, # % cover of the world surface of black breed
    albedo_white = 0.75,
    albedo_black = 0.25,
    surface_albedo = 0.4,
    solar_change = 0.005,
    solar_luminosity = 1.0, # initial luminosity
    scenario = :default,
    seed = 165,
)

    rng = MersenneTwister(seed)
    space = GridSpace(griddims)
    properties = (;max_age, surface_albedo, solar_luminosity, solar_change, scenario,)
    properties = Dict(pairs(properties))
    properties[:tick] = 0
    properties[:temperature] = zeros(griddims)

    model = ABM(Daisy, space; properties, rng)

    ## Populate with daisies: each position has only one daisy (black or white)
    grid = collect(positions(model))
    num_positions = prod(griddims)
    white_positions =
        StatsBase.sample(grid, Int(init_white * num_positions); replace = false)
    for wp in white_positions
        wd = Daisy(nextid(model), wp, :white, rand(model.rng, 0:max_age), albedo_white)
        add_agent_pos!(wd, model)
    end
    allowed = setdiff(grid, white_positions)
    black_positions =
        StatsBase.sample(allowed, Int(init_black * num_positions); replace = false)
    for bp in black_positions
        wd = Daisy(nextid(model), bp, :black, rand(model.rng, 0:max_age), albedo_black)
        add_agent_pos!(wd, model)
    end

    ## Adjust temperature to initial daisy distribution
    for p in positions(model)
        update_surface_temperature!(p, model)
    end

    return model, daisy_step!, daisyworld_step!
end
