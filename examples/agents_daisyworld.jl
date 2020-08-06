using InteractiveChaos, Makie
Random.seed!(165) # hide
model = daisyworld(; solar_luminosity = 1.0, solar_change = 0.0, scenario = :change)

# Thankfully, we have already defined the necessary `adata, mdata` as well as the agent
# color/shape/size functions, and we can re-use them for the interactive application.
# Unfortunately, because `InteractiveChaos` uses a different plotting package, Makie.jl, we have
# to redefine the plotting functions. However, in the near future where AgentsPlots.jl
# will move to Makie.jl, this will not be necessary.
using AbstractPlotting: to_color
daisycolor(a::Daisy) = RGBAf0(to_color(a.breed))
const landcolor = cgrad(:thermal)
daisycolor(a::Land) = to_color(landcolor[(a.temperature+50)/150])

daisyshape(a::Daisy) = '♣'
daisysize(a::Daisy) = 1.0
daisyshape(a::Land) = :rect
daisysize(a::Land) = 1

# The only difference is that we make a parameter container for surface albedo and
# for the rate of change of solar luminosity, and add some labels for clarity.

params = Dict(
    :solar_change => -0.1:0.01:0.1,
    :surface_albedo => 0:0.01:1,
)

alabels = ["black", "white", "T"]
mlabels = ["L"]

landfirst = by_type((Land, Daisy), false)

scene, agent_df, model_def = interactive_abm(
    model, agent_step!, model_step!, params;
    ac = daisycolor, am = daisyshape, as = daisysize,
    mdata = mdata, adata = adata, alabels = alabels, mlabels = mlabels,
    scheduler = landfirst # crucial to change model scheduler!
)
