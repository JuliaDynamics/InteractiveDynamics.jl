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
