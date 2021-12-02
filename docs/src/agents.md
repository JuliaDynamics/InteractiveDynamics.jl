# Agent based models
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/agents.mp4?raw=true" type="video/mp4">
</video>
```

This page describes functions that can be used in conjunction with [Agents.jl](https://juliadynamics.github.io/Agents.jl/dev/) to animate and interact with agent based models.

The animation at the start of this page was done by running the `examples/daisyworld.jl` file, and see also an example application in [Agents.jl docs](https://juliadynamics.github.io/Agents.jl/dev/examples/schelling/).

```@docs
abm_plot
abm_play
abm_video
abm_data_exploration
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

TODO: screenshot of output

This will always display the data as scatterpoints connected with lines.
In cases where more granular control over the displayed plots is needed, we need to take a few extra steps.
Makie plots have to know which changes in the underlying data to watch.
This is done by using `Observable`s.
We can simply add the variable in question as an `Observable` and update it after each simulation step.
This can be done by adding a new stepping function which wraps the original `model_step!` function and the updating of the `Observable`'s value.

```julia
# add the new variable as an observable
happiness = collect(a.mood for a in allagents(model)) |> Observable

# update its value after each model step
function new_model_step!(model, count_unhappy = count_unhappy)
    model_step!(model)
    happiness[] = collect(a.mood for a in allagents(model))
end

# open the interactive app and use the enhanced stepping function as an argument
fig, adf, mdf = abm_data_exploration(model, agent_step!, new_model_step!, params; adata)

# add the desired plot to a newly created column on the right
hist(fig[:,3], happiness)
```

TODO: screenshot of output
