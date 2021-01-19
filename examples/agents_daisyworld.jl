using InteractiveChaos
import GLMakie
using Agents
using Random, Statistics

Random.seed!(165) # hide
model, agent_step!, model_step! = Models.daisyworld(; solar_luminosity = 1.0, solar_change = 0.0, scenario = :change)
Daisy, Land = Agents.Models.Daisy, Agents.Models.Land

using AbstractPlotting: to_color
daisycolor(a::Daisy) = RGBAf0(to_color(a.breed))
landcolor = cgrad(:thermal)
daisycolor(a::Land) = to_color(landcolor[(a.temperature+50)/150])

daisyshape(a::Daisy) = '♣'
daisysize(a::Daisy) = 15
daisyshape(a::Land) = :rect
daisysize(a::Land) = 20
landfirst = by_type((Land, Daisy), false) # scheduler

# static daisyworld plot:
figure = abm_plot(
    model;
    ac = daisycolor, am = daisyshape, as = daisysize,
    scheduler = landfirst # crucial to change model scheduler!
)

# %% daisyworld video:
model, agent_step!, model_step! = Models.daisyworld(; solar_luminosity = 1.0, solar_change = 0.0, scenario = :change)
figure = abm_video(
    "daisyworld.mp4", model, agent_step!, model_step!;
    ac = daisycolor, am = daisyshape, as = daisysize,
    scheduler = landfirst, # crucial to change model scheduler!
    title = "Daisyworld"
)

# %% Parameter exploration and data collection:
params = Dict(
    :solar_change => -0.1:0.01:0.1,
    :surface_albedo => 0:0.01:1,
)

black(a) = a.breed == :black
white(a) = a.breed == :white
daisies(a) = a isa Daisy
land(a) = a isa Land
adata = [(black, count, daisies), (white, count, daisies), (:temperature, mean, land)]
mdata = [:solar_luminosity]

alabels = ["black", "white", "T"]
mlabels = ["L"]


figure, adf, mdf = abm_data_exploration(
    model, agent_step!, model_step!, params;
    ac = daisycolor, am = daisyshape, as = daisysize,
    mdata, adata, alabels, mlabels,
    scheduler = landfirst # crucial to change model scheduler!
)
