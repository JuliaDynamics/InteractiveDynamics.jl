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

as(agents_here) = 0.005 * length(agents_here)

function ac(agents_here)
    numagents = length(agents_here)
    infected = count(a.status == :I for a in agents_here)
    recovered = count(a.status == :R for a in agents_here)
    return RGBf(infected / numagents, recovered / numagents, 0)
end

edge_color(model) = fill((:grey, 0.25), ne(model.space.graph))

function edge_width(model)
    w = []
    for e in edges(model.space.graph)
        push!(w, 0.004 * length(model.space.stored_ids[e.src]))
        push!(w, 0.004 * length(model.space.stored_ids[e.dst]))
    end
    return w
end

graphplotkwargs = (
    layout = Shell(),
    arrow_show = false,
    edge_color = edge_color,
    edge_width = edge_width,
    edge_plottype = :linesegments
)

fig, ax, abmobs = abmplot(model; agent_step!, as, ac, graphplotkwargs)
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
    as, ac, graphplotkwargs)
fig

## abmvideo

model, agent_step!, model_step! = Models.sir()
abmvideo("testGraphSpace/abmvideo.mp4", model, agent_step!, model_step!;
    framerate = 10, frames = 100, title = "Social Distancing",
    as, ac, graphplotkwargs)
