# Agent based models
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/agents.mp4?raw=true" type="video/mp4">
</video>
```

This page describes functions that can be used in conjunction with [Agents.jl](https://juliadynamics.github.io/Agents.jl/dev/) to animate and interact with agent based models.

The animation at the start of this page was done by running the `examples/daisyworld.jl` file, and see also an example application in [Agents.jl docs](https://juliadynamics.github.io/Agents.jl/dev/examples/schelling/).

```@docs
abmplot
abmplot!
```

```
!!! note
    Please note that calling `abmplot` as a standalone function is currently not fully 
    supported. While it can be used to create relatively simple static plots, some of its 
    built-in functionality (e.g. heatmap colorbar, model controls, parameter sliders) will 
    not work out of the box.

    It is strongly advised to first explicitly construct a Figure and Axis to plot into, 
    then provide `ax::Axis` as a keyword argument to your in-place function call.

    Example:
        fig = Figure()
        ax = Axis(fig[1,1])
        p = abmplot!(model; ax)
```

## Convenience functions

There are currently two extra convenience functions that execute the `abmplot` recipe under specific conditions.
These can be helpful for having a quick look at time series of collected data (`abm_data_exploration`) or for recording the evolution of a model and saving it in a video file (`abm_video`).

```@docs
abm_data_exploration
abm_video
```

## Agent inspection

It is possible to inspect agents at a given position by hovering the mouse cursor over the scatter points in the agent plot.
A tooltip will appear which by default provides the name of the agent type, its `id`, `pos`, and all other fieldnames together with their current values.
This is especially useful for interactive exploration of micro data on the agent level.

For this functionality, we draw on the powerful features of Makie's [`DataInspector`](https://makie.juliaplots.org/v0.15.1/documentation/inspector/).

The tooltip can be customized both with regards to its content and its style by extending a single function and creating a specialized method for a given `A<:AbstractAgent`.

```@docs
agent2string
```

## Adding custom plots

Tracking model variables is already made easy by adding them to the `adata`/`mdata` vectors.

```julia
using Agents
using Statistics
using InteractiveDynamics
using GLMakie

# initialise model
model, agent_step!, model_step! = Models.schelling()

# define a parameter slider
params = Dict(:min_to_be_happy => 1:1:5)

# define data to collect and plot
adata= [(:mood, mean)]

# open the interactive app
fig, adf, mdf = abm_data_exploration(model, agent_step!, model_step!, params; adata)
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
# add the new variable as an observable
happiness = [count(a.mood == false for a in allagents(model)),
    count(a.mood == true for a in allagents(model))] |> Observable

# update its value after each model step
function new_model_step!(model; happiness = happiness)
    model_step!(model)
    happiness[] = [count(a.mood == false for a in allagents(model)),
        count(a.mood == true for a in allagents(model))]
end

# open the interactive app and use the enhanced stepping function as an argument
fig, adf, mdf = abm_data_exploration(model, agent_step!, new_model_step!, params; adata)

# add the desired plot to a newly created column on the right
barplot(fig[:,3], [0,1], happiness; bar_labels = ["Unhappy", "Happy"])

# as usual, we can also style this new plot to our liking
hidexdecorations!(current_axis())
```

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/custom_plots.mp4?raw=true" type="video/mp4">
</video>
```
