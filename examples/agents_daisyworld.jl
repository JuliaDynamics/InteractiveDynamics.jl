using InteractiveChaos, GLMakie
using Agents
using Random, Statistics

Random.seed!(165) # hide
model, agent_step!, model_step! = Models.daisyworld(; solar_luminosity = 1.0, solar_change = 0.0, scenario = :change)
Daisy, Land = Agents.Models.Daisy, Agents.Models.Land

using AbstractPlotting: to_color
daisycolor(a::Daisy) = RGBAf0(to_color(a.breed))
const landcolor = cgrad(:thermal)
daisycolor(a::Land) = to_color(landcolor[(a.temperature+50)/150])

daisyshape(a::Daisy) = '♣'
daisysize(a::Daisy) = 10
daisyshape(a::Land) = :rect
daisysize(a::Land) = 15

params = Dict(
    :solar_change => -0.1:0.01:0.1,
    :surface_albedo => 0:0.01:1,
)

black(y) = count(x -> x == :black, y)
white(y) = count(x -> x == :white, y)
breed(a) = a isa Daisy ? a.breed : :land
gettemperature(a) = a isa Land ? a.temperature : missing
meantemperature(x) = mean(skipmissing(x))
adata = [(breed, black), (breed, white), (gettemperature, meantemperature)]
mdata = [:solar_luminosity]

alabels = ["black", "white", "T"]
mlabels = ["L"]

landfirst = by_type((Land, Daisy), false)

scene, agent_df, model_def = interactive_abm(
    model, agent_step!, model_step!, params;
    ac = daisycolor, am = daisyshape, as = daisysize,
    mdata, adata, alabels, mlabels,
    scheduler = landfirst # crucial to change model scheduler!
)
