## InteractiveDynamics test area

using Agents, Random, DataFrames
using Agents.Graphs
using InteractiveDynamics
using GLMakie
using Statistics
using GraphMakie.NetworkLayout

## abmplot

model, agent_step!, model_step! = Models.sir()
graphplotkwargs = (; layout = Shell(), arrow_show = false)
fig, ax, abmobs = abmplot(model; graphplotkwargs)
fig

## abmplot with abmobs instead of model
model, agent_step!, model_step! = Models.sir()
abmobs = ABMObservable(model; agent_step!)
fig, ax, abmobs = abmplot(abmobs; graphplotkwargs)
fig

## abmexploration

model, agent_step!, model_step! = Models.sir()
fig, abmobs = abmexploration(model; agent_step!, graphplotkwargs)
fig

## dynamic sizes, colors, markers...

model, agent_step!, model_step! = Models.sir()

city_size(model, pos) = 20 + 0.005 * length(model.space.stored_ids[pos])

function city_color(model, pos)
    agents_here = count(a.pos == pos for a in allagents(model))
    infected = count((a.pos == pos && a.status == :I) for a in allagents(model))
    recovered = count((a.pos == pos && a.status == :R) for a in allagents(model))
    return RGBf(infected / agents_here, recovered / agents_here, 0)
end

edge_color(model) = fill((:grey, 0.25), ne(model.space.graph))

function edge_width(model)
    w = []
    for e in edges(model.space.graph)
        push!(w, city_size(model, e.src) - 20)
        push!(w, city_size(model, e.dst) - 20)
    end
    return w
end

graphplotkwargs = (
    layout = Shell(),
    arrow_show = false,
    edge_color = edge_color,
    edge_width = edge_width,
    edge_plottype = :linesegments # needed for tapered edge widths and bi-colored edges
)

fig, ax, abmobs = abmplot(model;
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

model, agent_step!, model_step! = Models.sir()
fig, abmobs = abmexploration(model; 
    agent_step!, params = exploration_params, 
    mdata = [population, count_infected, count_recovered], 
    as = city_size, ac = city_color, graphplotkwargs)
fig

## abmvideo

model, agent_step!, model_step! = Models.sir()
abmvideo("testGraphSpace/abmvideo.mp4", model, agent_step!, model_step!;
    framerate = 10, frames = 100, title = "Social Distancing",
    as = city_size, ac = city_color, graphplotkwargs)
