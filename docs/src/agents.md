# Agent based models
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/agents.mp4?raw=true" type="video/mp4">
</video>
```

This page describes functions that can be used in conjunction with [Agents.jl](https://juliadynamics.github.io/Agents.jl/dev/) to animate and interact with agent based models.

The animation at the start of this page was done by running the `examples/agents/agents_daisyworld.jl` file.
Another example application can be found in the [Agents.jl docs](https://juliadynamics.github.io/Agents.jl/dev/examples/schelling/).

## ABMPlot recipe

```@docs
abmplot
```

## Convenience functions

There are currently two extra convenience functions that can be helpful for having a quick look at time series of collected data ([`abmexploration`](@ref)) or for recording the evolution of a model and saving it in a video file ([`abmvideo`](@ref)).

```@docs
abmexploration
abmvideo
```

## Agent inspection

It is possible to inspect agents at a given position by hovering the mouse cursor over the scatter points in the agent plot.
A tooltip will appear which by default provides the name of the agent type, its `id`, `pos`, and all other fieldnames together with their current values.
This is especially useful for interactive exploration of micro data on the agent level.

For this functionality, we draw on the powerful features of Makie's [`DataInspector`](https://makie.juliaplots.org/dev/documentation/inspector/).

![RabbitFoxHawk inspection example](https://github.com/JuliaDynamics/JuliaDynamics/tree/master/videos/agents/RabbitFoxHawk_inspection.png)

The tooltip can be customized both with regards to its content and its style by extending a single function and creating a specialized method for a given `A<:AbstractAgent`.

```@docs
InteractiveDynamics.agent2string
```

## Adding custom plots

Tracking model variables is already made easy by adding them to the `adata`/`mdata` vectors.
The provided [convenience function](@ref) `abmexploration` then allows for easily exploring the model dynamics by looking at the plots which are automatically created for each tracked variable in `adata`/`mdata`.

```julia
using Agents
using Statistics
using InteractiveDynamics
using GLMakie

# initialise model
model, daisy_step!, daisyworld_step! = Models.daisyworld(; solar_luminosity = 1.0, solar_change = 0.0, scenario = :change)

# define plot details
daisycolor(a::Daisy) = a.breed

plotkwargs = (
    ac = daisycolor, as = 12, am = '♠',
    heatarray = :temperature,
    heatkwargs = (colorrange = (-20, 60),),
)

# define parameter sliders
params = Dict(
    :surface_albedo => 0:0.01:1,
    :solar_change => -0.1:0.01:0.1,
)

# define data to collect and plot
black(a) = a.breed == :black
white(a) = a.breed == :white
adata = [(black, count), (white, count)]
temperature(model) = mean(model.temperature)
mdata = [temperature, :solar_luminosity]

# open the interactive app
fig, p = abmexploration(model;
    agent_step! = daisy_step!, model_step! = daisyworld_step!, params,
    adata, alabels = ["Black daisys", "White daisys"], mdata, mlabels = ["T", "L"]
)
```

```@raw html
<img width="100%" height="auto" alt="Regular interactive app for data exploration" src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/custom_plots.png">
```

This will always display the data as scatterpoints connected with lines.
In cases where more granular control over the displayed plots is needed, we need to take a few extra steps.
Makie plots have to know which changes in the underlying data to watch.
This is done by using `Observable`s.
We can simply add the variable in question as an `Observable` and update it after each simulation step.
This can be done by adding a new stepping function which wraps the original `model_step!` function and the updating of the `Observable`'s value.

For the sake of a simple example, let's assume we want to add a barplot showing the current amount of happy and unhappy agents in our Schelling segregation model.

```julia
# reset model
model = daisyworld(; solar_luminosity = 1.0, solar_change = 0.0, scenario = :change)

# create a basic abmplot with controls and sliders
fig, ax, p = abmplot(model;
        agent_step! = daisy_step!, model_step! = daisyworld_step!,
        params, mdata, adata, figure = (; resolution = (1600,800)), plotkwargs...)

display(fig)

# create a new layout to add new plots to to the right of the abmplot
plot_layout = fig[:,end+1] = GridLayout()

# create a sublayout on its first row and column
count_layout = plot_layout[1,1] = GridLayout()

# collect tuples with x and y values for black and white daisys
blacks = @lift(Point2f.($(p.adf).step, $(p.adf).count_black))
whites = @lift(Point2f.($(p.adf).step, $(p.adf).count_white))

# create an axis to plot into and style it to our liking
ax_counts = Axis(count_layout[1,1];
    backgroundcolor = :lightgrey, ylabel = "Number of daisys by color")

# plot the data as scatterlines and color them accordingly
scatterlines!(ax_counts, blacks; color = :black, label = "black")
scatterlines!(ax_counts, whites; color = :white, label = "white")

# add a legend to the right side of the plot
Legend(count_layout[1,2], ax_counts, bgcolor = :lightgrey)

# and another plot, written in a more condensed format
hist(plot_layout[2,1], @lift($(p.mdf).temperature);
    bins = 10, color = GLMakie.Colors.colorant"#d31",
    strokewidth = 2, strokecolor = (:black, 0.5),
    axis = (; ylabel = "Distribution of mean temperatures\nacross all time steps")
)
```

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/custom_plots.mp4?raw=true" type="video/mp4">
</video>
```
