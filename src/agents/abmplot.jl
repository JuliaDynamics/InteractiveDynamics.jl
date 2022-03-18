export abmplot, abmplot!

"""
    abmplot(model::ABM; kwargs...) → fig, ax, abmplot_object
    abmplot!(ax::Axis/Axis3, model::ABM; kwargs...) → abmplot_object

Plot an agent based model by plotting each individual agent as a marker and using
the agent's position field as its location on the plot. The same function can be used
to launch interactive applications for the model evolution,
see Interactive Application below.

The returned `abmplot_object` can be used to make custom compositions of plots and
animations as illustrated in the online documentation.

Requires `Agents`.

## Keyword arguments

The stand-alone function `abmplot` takes two optional `NamedTuple`s named `figure` and `axis` which can be used to change the automatically created `Figure` and `Axis` objects.

### Agent related
* `ac, as, am` : These three keywords decided the color, size, and marker, that
  each agent will be plotted as. They can each be either a constant or a *function*,
  which takes as an input a single argument and outputs the corresponding value.

  Using constants: `ac = "#338c54", as = 10, am = :diamond`

  Using functions:
  ```julia
  ac(a) = a.status == :S ? "#2b2b33" : a.status == :I ? "#bf2642" : "#338c54"
  as(a) = 10*randn() + 1
  am(a) = a.status == :S ? :circle : a.status == :I ? :diamond : :rect
  ```
  Notice that for 2D models, `am` can be/return a `Polygon` instance, which plots each agent
  as an arbitrary polygon. It is assumed that the origin (0, 0) is the agent's position when
  creating the polygon. In this case, the keyword `as` is meaningless, as each polygon has
  its own size. Use the functions `scale, rotate2D` to transform this polygon.

  3D models currently do not support having different markers. As a result, `am` cannot be
  a function. It should be a `Mesh` or 3D primitive (such as `Sphere` or `Rect3D`).
* `offset = nothing` : If not `nothing`, it must be a function taking as an input an
  agent and outputting an offset position tuple to be added to the agent's position
  (which matters only if there is overlap).
* `scatterkwargs = ()` : Additional keyword arguments propagated to the `scatter!` call.

### Preplot related
* `heatarray = nothing` : A keyword that plots a heatmap over the space.
  Its values can be standard data accessors given to functions like `run!`, i.e.
  either a symbol (directly obtain model property) or a function of the model.
  The returned data must be a matrix of the same size as the underlying space.
  For example `heatarray = :temperature` is used in the Daisyworld example.
  But you could also define `f(model) = create_matrix_from_model...` and set
  `heatarray = f`. The heatmap will be updated automatically during model evolution
  in videos and interactive applications.
* `heatkwargs = NamedTuple()` : Keywords given to `Makie.heatmap` function
  if `heatarray` is not nothing.
* `add_colorbar = true` : Whether or not a Colorbar should be added to the right side of the
  heatmap if `heatarray` is not nothing.
* `static_preplot!` : A function `f(ax, model)` that plots something after the heatmap
  but before the agents. Notice that you can still make objects of this plot be visible
  above the agents using a translation in the third dimension like below:
  ```julia
  function static_preplot!(ax, model)
      obj = scatter!(ax, [50 50]; color = :red) # Show position of teacher
      hidedecorations!(ax) # hide tick labels etc.
      translate!(obj, 0, 0, 5) # be sure that the teacher will be above students
  end
  ```

### Plot layers inside `_ABMPlot`

  1. OSMPlot, if `model.space isa OpenStreetMapSpace`
  2. static preplot, if `static_preplot! != nothing`
  3. heatmap, if `heatarray != nothing`
  4. agent positions as `scatter`, `poly` or `meshscatter`, depending on type of `model.space`


# Interactive Application
If either, or both, of the keywords `agent_step!, model_step!` are provided, the
plot switches to an interactive application mode.
The two functions `agent_step!, model_step!` will decide how
the model will evolve, as in the standard approach of Agents.jl and its `step!` function.

The application has four buttons:

* "step": advances the simulation once for `spu` steps.
* "run": starts/stops the continuous evolution of the model.
* "reset model": resets the model to its initial state from right after starting the
  interactive application.
* "clear data": deletes previously collected agent and model data by emptying the underlying
  DataFrames `adf`/`mdf`. Reset model and clear data are independent processes.

Two sliders control the animation speed: "spu" decides how many model steps should be done
before the plot is updated, and "sleep" the `sleep()` time between updates.

## Keywords arguments for interactive application
* `params = Dict()` : This is a dictionary which decides which parameters of the model will
  be configurable from the interactive application. Each entry of `params` is a pair of
  `Symbol` to an `AbstractVector`, and provides a range of possible values for the parameter
  named after the given symbol (see example online). Changing a value in the parameter
  slides is only propagated to the actual model after a press of the "update" button.
* `agent_step!, model_step! = nothing` : If one or both aren't nothing, interactive buttons
  for model control will be added to the resulting figure.
* `adata, mdata = []` : Same as the keyword arguments of `Agents.run!`. If either or both
  aren't empty, data are collected and stored in the `abmplot_object` `.adf` and `.mdf`
  fields as observables that can be lifted from.
* `spu = 1:50`: The values of the "spu" slider.
* `when = true` : When to perform data collection, as in `Agents.run!`.
"""
function abmplot(model::Agents.ABM; figure = NamedTuple(), axis = NamedTuple(), kwargs...)
    fig = Figure(; figure...)
    ax = fig[1,1] = agents_space_dimensionality(model) == 3 ?
        Axis3(fig; axis...) : Axis(fig; axis...)
    p = _abmplot!(model; ax, kwargs...)

    return fig, ax, p
end

abmplot!(ax, model::Agents.ABM; kwargs...) = _abmplot!(ax, model; ax, kwargs...)

"""
    _abmplot(model::ABM; kwargs...) → fig, ax, abmplot_object
    _abmplot!(model::ABM; ax::Axis/Axis3, kwargs...) → abmplot_object

This is the internal recipe for creating an `_ABMPlot`.
It is not intended to be used directly. Please use `abmplot`/`abmplot!` instead.
"""
@recipe(_ABMPlot, model) do scene
    Theme(
        # insert InteractiveDynamics theme here?
    )
    Attributes(
        # Axis
        # ax is currently necessary to have a reference to the parent Axis. This is needed
        # for optional Colorbar of heatmap and optional buttons/sliders.
        # Makie's recipe system still works on the old system of Scenes which have no
        # concept of a parent Axis. Makie devs plan to enable this in the future. Until then
        # we will have to work around it with this "little hack".
        ax = nothing,

        # Agent
        ac = JULIADYNAMICS_COLORS[1],
        as = 10,
        am = :circle,
        offset = nothing,
        scatterkwargs = NamedTuple(),

        # Preplot
        heatarray = nothing,
        heatkwargs = NamedTuple(),
        add_colorbar = true,
        static_preplot! = nothing,

        # Interactive application
        # Add parameter sliders if params are provided
        params = Dict(),
        # Add controls if agent_step! and/or model_step! are provided
        agent_step! = Agents.dummystep,
        model_step! = Agents.dummystep,
        adata = nothing,
        mdata = nothing,
        adf = nothing,
        mdf = nothing,
        spu = 1:50,
        when = true,

        # Internal Attributes necessary for inspection, controls, etc. to work
        _used_poly = false,
    )
end

const SUPPORTED_SPACES =  Union{
    Agents.DiscreteSpace,
    Agents.ContinuousSpace,
    Agents.OpenStreetMapSpace,
}

function Makie.plot!(abmplot::_ABMPlot{<:Tuple{<:Agents.ABM{<:SUPPORTED_SPACES}}})
    # Following attributes are all lifted from the recipe observables (specifically,
    # the model), see lifting.jl for source code.
    pos, color, marker, markersize, heatobs = lift_attributes(abmplot.model, abmplot.ac,
        abmplot.as, abmplot.am, abmplot.offset, abmplot.heatarray, abmplot._used_poly)

    model = abmplot.model[]
    ax = abmplot.ax[]
    if !isnothing(ax)
        isnothing(ax.aspect[]) && (ax.aspect = DataAspect())
        set_axis_limits!(ax, model)
        fig = ax.parent
    end

    # OpenStreetMapSpace preplot
    if model.space isa Agents.OpenStreetMapSpace
        osm_plot = osmplot!(abmplot, model.space.map)
        osm_plot.plots[1].plots[1].plots[1].inspectable[] = false
        osm_plot.plots[1].plots[3].inspectable[] = false
    end

    # Heatmap
    if !isnothing(heatobs[])
        hmap = heatmap!(abmplot, heatobs; colormap = JULIADYNAMICS_CMAP, abmplot.heatkwargs...)
        if abmplot.add_colorbar[]
            @assert !isnothing(ax) "Need `ax` to add a colorbar for the heatmap."
            Colorbar(fig[1,end+1], hmap, width = 20)
        end
    end

    # Static preplot
    if !isnothing(abmplot.static_preplot![])
        static_plot = abmplot.static_preplot![](abmplot, model)
        static_plot.inspectable[] = false
    end

    # Dispatch on type of agent positions
    T = typeof(pos[])
    if T<:Vector{Point2f} # 2d space
        if typeof(marker[])<:Vector{<:Polygon{2}}
            poly_plot = poly!(abmplot, marker; color, abmplot.scatterkwargs...)
            poly_plot.inspectable[] = false # disable inspection for poly until fixed
        else
            scatter!(abmplot, pos; color, marker, markersize, abmplot.scatterkwargs...)
        end
    elseif T<:Vector{Point3f} # 3d space
        marker[] == :circle && (marker = Sphere(Point3f(0), 1))
        meshscatter!(abmplot, pos; color, marker, markersize, abmplot.scatterkwargs...)
    else
        @warn("""
            Cannot resolve agent positions: $(T)
            Skipping plotting agents.
            """)
    end

    # Model controls, parameter sliders, data plots
    !isnothing(ax) && add_interaction!(fig, ax, abmplot)

    return abmplot
end

"Plot space and/or set axis limits."
function set_axis_limits!(ax, model)
    if model.space isa Agents.OpenStreetMapSpace
        return
    elseif model.space isa Agents.ContinuousSpace
        e = model.space.extent
    elseif model.space isa Agents.DiscreteSpace
        e = size(model.space.s) .+ 1
    end
    o = zero.(e)
    xlims!(ax, o[1], e[1])
    ylims!(ax, o[2], e[2])
    is3d = length(o) == 3
    is3d && zlims!(ax, o[3], e[3])
    return
end

@deprecate abm_plot abmplot

# Extend `step!` for observable
function Agents.step!(model::Observable{<:Agents.ABM}, args...; kwargs...)
    m = model[]
    Agents.step!(m, args...; kwargs...)
    model[] = m
    return
end