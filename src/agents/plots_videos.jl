export abm_plot, abm_play, abm_video

dimensionality(::Agents.ABM{<:Agents.GridSpace{D}}) where {D} = D
dimensionality(::Agents.ABM{<:Agents.ContinuousSpace{D}}) where {D} = D

"""
    abm_plot(model::ABM; kwargs...) → fig, abmstepper
Plot an agent based model by plotting each individual agent as a marker and using
the agent's position field as its location on the plot. Requires `Agents`.

Return the overarching `fig` object, as well as a struct `abmstepper` that can be used
to interactively animate the evolution of the ABM and combine it with other subplots.
The figure is not displayed by default, you need to either return `fig` as a last statement
in your functions or simply call `display(fig)`.
Notice that models with `DiscreteSpace` are plotted starting from 0 to n, with
n the space size along each dimension.

To progress the ABM plot `n` steps simply do:
```julia
Agents.step!(abmstepper, model, agent_step!, model_step!, n)
```
You can still call this function with `n=0` to update the plot for a new `model`,
without doing any stepping. From `fig` you can obtain the plotted axis (to e.g. turn
off ticks, etc.) using `ax = content(fig[1, 1])`.
See [Sugarscape](@ref) for an example of using `abmstepper` to make an animation of
evolving the ABM and a heatmap in parallel with only a few lines of code.

## Agent related keywords
* `ac, as, am`: These three keywords decided the color, size, and marker, that
  each agent will be plotted as. They can each be either a constant or a *function*,
  which takes as an input a single argument and ouputs the corresponding value.
  For example:
  ```julia
  # ac = "#338c54"
  ac(a) = a.status == :S ? "#2b2b33" : a.status == :I ? "#bf2642" : "#338c54"
  # as = 10
  as(a) = 10*randn() + 1
  # am = :diamond
  am(a) = a.status == :S ? :circle : a.status == :I ? :diamond : :rect
  ```
  Notice that for 2D models, `am` can be/return a `Polygon` instance, which plots each agent
  as an arbitrary polygon. It is assumed that the origin (0, 0) is the agent's position when
  creating the polygon. In this case, the keyword `as` is meaningless, as each polygon has its
  own size. Use the functions `scale, rotate2D` to transform this polygon.

  3D models currently do not support having different markers. As a result, `am` cannot be a function.
  It should be a `Mesh` or 3D primitive (such as `Sphere` or `Rect3D`).
* `scheduler = model.scheduler`: decides the plotting order of agents
  (which matters only if there is overlap).
* `offset = nothing`: If not `nothing`, it must be a function taking as an input an
  agent and outputting an offset position vector to be added to the agent's position
  (which matters only if there is overlap).
* `scatterkwargs = ()`: Additional keyword arguments propagated to the resulting ABMPlot.

## Figure related keywords
* `resolution = (600, 600)`: Resolution of the figure.
* `colorscheme = JULIADYNAMICS_COLORS`: Vector of colors which is used as default colorscheme
  in the figure.
* `backgroundcolor = DEFAULT_BG`: Background color of the figure.
* `axiskwargs = NamedTuple()`: Keyword arguments given to the main axis creation for e.g.
  setting `xticksvisible = false`.
* `aspect = DataAspect()`: The aspect ratio behavior of the axis.

## Preplot related keywords
* `heatarray = nothing` : A keyword that plots a heatmap over the space.
  Its values can be standard data accessors given to functions like `run!`, i.e.
  either a symbol (directly obtain model property) or a function of the model.
  The returned data must be a matrix of the same size as the underlying space.
  For example `heatarray = :temperature` is used in the [Daisyworld](@ref) example.
  But you could also define `f(model) = create_some_matrix_from_model...` and set
  `heatarray = f`. The heatmap will be updated automatically during model evolution
  in videos and interactive applications.
* `heatkwargs = NamedTuple()` : Keywords given to `Makie.heatmap` function
  if `heatarray` is not nothing.
* `static_preplot!` : A function `f(ax, model)` that plots something after the heatmap
  but before the agents. Notice that you can still make objects of this plot be visible
  above the agents using a translation in the third dimension like below:
  ```julia
  function static_preplot!(ax, model)
      obj = CairoMakie.scatter!([50 50]; color = :red) # Show position of teacher
      CairoMakie.hidedecorations!(ax) # hide tick labels etc.
      CairoMakie.translate!(obj, 0, 0, 5) # be sure that the teacher will be above students
  end
  ```
"""
function abm_plot(model;
    resolution = (600, 600), colorscheme = JULIADYNAMICS_COLORS,
    backgroundcolor = DEFAULT_BG, axiskwargs = NamedTuple(), aspect = DataAspect(),
    as = 10, am = :circle, offset = nothing,
    heatarray = nothing, heatkwargs = NamedTuple(), add_colorbar = true,
    static_preplot! = default_static_preplot, scatterkwargs = NamedTuple(),
    kwargs...
)
    ac = get(kwargs, :ac, colorscheme[1])
    scheduler = get(kwargs, :scheduler, model.scheduler)

    fig = Figure(; resolution, backgroundcolor)
    ax = fig[1, 1][1, 1] = dimensionality(model) == 3 ?
                           Axis3(fig; axiskwargs...) : Axis(fig; axiskwargs...)
    abmstepper = abm_init_stepper(model;
        ac, as, am, scheduler, offset, heatarray)
    abm_init_plot!(ax, fig, model, abmstepper;
        aspect, heatkwargs, add_colorbar, static_preplot!, scatterkwargs)
    inspector = DataInspector(fig.scene)

    # temporarily disable inspector for poly plots
    if user_used_polygons(am, abmstepper.markers)
        inspector.plot.enabled = false
    end

    return fig, abmstepper
end

##########################################################################################

"""
    abm_play(model, agent_step! [, model_step!]; kwargs...) → fig, abmstepper
Launch an interactive application that plots an agent based model and can animate
its evolution in real time. Requires `Agents`.

The agents are plotted exactly like in [`abm_plot`](@ref), while the two functions
`agent_step!, model_step!` decide how the model will evolve, as in the standard
approach of Agents.jl and its `step!` function.

The application has three buttons:

* "step": advances the simulation once for `spu` steps.
* "run": starts/stops the continuous evolution of the model.
* "reset": resets the model to its original configuration. 

Two sliders control the animation speed: "spu" decides how many model steps should be done
before the plot is updated, and "sleep" the `sleep()` time between updates.

## Keywords
* `ac, am, as, scheduler, offset, aspect, scatterkwargs`: propagated to [`abm_plot`](@ref).
* `spu = 1:100`: The values of the "spu" slider.
"""
function abm_play(
    model, agent_step!, model_step! = Agents.dummystep;
    spu = 1:100, kwargs...
)
    fig, abmstepper = abm_plot(model; resolution = (600, 700), kwargs...)
    abm_play!(fig, abmstepper, model, agent_step!, model_step!; spu)
    display(fig)
    return fig, abmstepper
end

function abm_play!(fig, abmstepper, model, agent_step!, model_step!; spu)
    # preinitialize a bunch of stuff
    model0 = deepcopy(model)
    modelobs = Observable(model) # only useful for resetting
    speed, slep, step, run, reset, = abm_controls!(fig, model, spu, false)

    # Clicking the "step" button
    on(step) do clicks
        n = speed[]
        model = modelobs[] # necessary after resetting the model
        Agents.step!(abmstepper, model, agent_step!, model_step!, n)
    end

    # Clicking the "run" button
    isrunning = Observable(false)
    on(run) do clicks
        isrunning[] = !isrunning[]
    end
    on(run) do clicks
        @async while isrunning[]
            step[] = step[] + 1
            slep[] == 0 ? yield() : sleep(slep[])
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window.
        end
    end

    # Clicking the "reset" button
    on(reset) do clicks
        modelobs[] = deepcopy(model0)
        model = modelobs[]
        Agents.step!(abmstepper, model, agent_step!, model_step!, 0)
    end

    return nothing
end

function abm_controls!(fig, model, spu, data_exploration = false)
    controllayout = fig[2, 1] = GridLayout(tellheight = true)
    spusl = labelslider!(fig, "spu =", spu; tellwidth = true)
    if model.space isa Agents.ContinuousSpace
        _s, _v = 0:0.01:1, 0
    else
        _s, _v = 0:0.1:10, 1
    end
    slesl = labelslider!(fig, "sleep =", _s, sliderkw = Dict(:startvalue => _v))
    controllayout[1, :] = spusl.layout
    controllayout[2, :] = slesl.layout
    step = Button(fig, label = "step")
    run = Button(fig, label = "run")
    reset = Button(fig, label = "reset")
    if data_exploration
        clear = Button(fig, label = "clear\nall")
        update = Button(fig, label = "update")
        controllayout[3, :][:, 1] = MakieLayout.hbox!(clear; tellwidth = false)
        controllayout[3, :][:, 2] = MakieLayout.hbox!(step, run; tellwidth = false)
        controllayout[3, :][:, 3] = MakieLayout.hbox!(reset, update; tellwidth = false)
        upret = update.clicks
        clearret = clear.clicks
    else
        controllayout[3, :][:, 2] = MakieLayout.hbox!(step, run; tellwidth = false)
        controllayout[3, :][:, 3] = MakieLayout.hbox!(reset; tellwidth = false)
        upret = nothing
        clearret = nothing
    end
    return spusl.slider.value, slesl.slider.value, step.clicks, run.clicks, reset.clicks, clearret, upret
end


##########################################################################################
"""
    abm_video(file, model, agent_step! [, model_step!]; kwargs...)
This function exports the animated time evolution of an agent based model into a video
saved at given path `file`, by recording the behavior of [`abm_play`](@ref) (without sliders).
The plotting is identical as in [`abm_plot`](@ref) and applicable keywords are propagated.

## Keywords
* `spf = 1`: Steps-per-frame, i.e. how many times to step the model before recording a new
  frame.
* `framerate = 30`: The frame rate of the exported video.
* `frames = 300`: How many frames to record in total, including the starting frame.
* `title = ""`: The title of the figure.
* `showstep = true`: If current step should be shown in title.
* `kwargs...`: All other keywords are propagated to [`abm_plot`](@ref).
"""
function abm_video(
    file, model, agent_step!, model_step! = Agents.dummystep;
    spf = 1, framerate = 30, frames = 300, title = "", showstep = true,
    resolution = (600, 600), colorscheme = JULIADYNAMICS_COLORS,
    backgroundcolor = DEFAULT_BG, axiskwargs = NamedTuple(), aspect = DataAspect(),
    as = 10, am = :circle, offset = nothing,
    heatarray = nothing, heatkwargs = NamedTuple(), add_colorbar = true,
    static_preplot! = default_static_preplot, scatterkwargs = NamedTuple(),
    kwargs...
)
    ac = get(kwargs, :ac, colorscheme[1])
    scheduler = get(kwargs, :scheduler, model.scheduler)

    # add some title stuff
    s = Observable(0) # counter of current step
    if title ≠ "" && showstep
        t = lift(x -> title * ", step = " * string(x), s)
    elseif showstep
        t = lift(x -> "step = " * string(x), s)
    else
        t = title
    end
    axiskwargs = (title = t, titlealign = :left, axiskwargs...)

    fig, abmstepper = abm_plot(model;
        resolution, colorscheme, backgroundcolor, axiskwargs, aspect,
        ac, as, am, scheduler, offset,
        heatarray, heatkwargs, add_colorbar,
        static_preplot!, scatterkwargs
    )

    record(fig, file; framerate) do io
        for j = 1:frames-1
            recordframe!(io)
            Agents.step!(abmstepper, model, agent_step!, model_step!, spf)
            s[] += spf
            s[] = s[]
        end
        recordframe!(io)
    end
    return nothing
end
