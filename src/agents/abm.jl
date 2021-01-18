export abm_plot
export abm_play
export abm_video

"""
    abm_plot(model::ABM; kwargs...) → figure
Plot an agent based model by plotting each individual agent as a marker and using
the agent's position field as its location on the plot. Requires `Agents`.

## Keywords
* `ac, as, am`: These three keywords decided the color, size, and marker, that
  each agent will be plotted as. They can each be either a constant or a *function*,
  which takes as an input a single argument and ouputs the corresponding value.
  For example:
  ```julia
  # ac = "#338c54"
  ac(a) = a.status == :S ? "#2b2b33" : a.status == :I ? "#bf2642" : "#338c54"
  # as = 10
  as(a) = 10*randn() + 1
  # as = :diamond
  as(a) = a.status == :S ? :circle : a.status == :I ? :diamond : :rect
  ```
* `scheduler = model.scheduler`: decides the plotting order of agents
  (which matters only if there is overlap).
* `offset = nothing`: If not `nothing`, it must be a function taking as an input an
  agent and outputting an offset position vector to be added to the agent's position
  (which matters only if there is overlap).
* `equalaspect = true`: Whether the plot should be of equal aspect ratio.
* `scatterkwargs = ()`: Additional keyword arguments propagated to the scatter plot.
* `resolution = (600, 600)`: Resolution of the figure.
"""
function abm_plot(model; resolution = (600, 600), kwargs...)
    figure = Figure(; resolution)
    ax = figure[1,1] = Axis(figure)
    pos = abm_plot!(ax, model; kwargs...)
    return figure
end

function abm_plot!(abmax, model;
        ac = JULIADYNAMICS_COLORS[1],
        as = 1,
        am = :circle,
        scheduler = model.scheduler,
        offset = nothing,
        equalaspect = true,
        scatterkwargs = NamedTuple(),
    )

    o, e = modellims(model) # TODO: extend to 3D
    @assert length(o) == 2 "At the moment only 2D spaces can be plotted."
    # TODO: once grid plotting is possible, this will be adjusted
    @assert typeof(model.space) <: Union{Agents.ContinuousSpace, Agents.DiscreteSpace}

    ids = scheduler(model)
    colors  = ac isa Function ? Observable(to_color.([ac(model[i]) for i ∈ ids])) : to_color(ac)
    sizes   = as isa Function ? Observable([as(model[i]) for i ∈ ids]) : as
    markers = am isa Function ? Observable([am(model[i]) for i ∈ ids]) : am
    if offset == nothing
        pos = Observable([model[i].pos for i ∈ ids])
    else
        pos = Observable([model[i].pos .+ offset(model[i]) for i ∈ ids])
    end

    scatter!(
        abmax, pos;
        color = colors, markersize = sizes, marker = markers, strokewidth = 0.0,
        scatterkwargs...
    )
    # TODO: This should be expanded into 3D
    xlims!(abmax, o[1], e[1])
    ylims!(abmax, o[2], e[2])
    equalaspect && (abmax.aspect = AxisAspect(1))

    return pos, colors, sizes, markers
end

function modellims(model)
    if model.space isa Agents.ContinuousSpace
        e = model.space.extent
        o = zero.(e) .+ 0.5
    elseif model.space isa Agents.DiscreteSpace
        e = size(model.space.s) .+ 1
        o = zero.(e)
    end
    return o, e
end


"""
    abm_play(model, agent_step!, model_step!; kwargs...) → figure
Launch an interactive application that plots an agent based model and can animate
its evolution in real time. Requires `Agents`.

The agents are plotted exactly like in [`abm_plot`](@ref), while the two functions
`agent_step!, model_step!` decide how the model will evolve, as in the standard
approach of Agents.jl and its `step!` function.

The application has two buttons: "run" and "reset" which starts/stops the time evolution
and resets the model to its original configuration.
Two sliders control the animation speed: "spu" decides how many model steps should be done
before the plot is updated, and "sleep" the `sleep()` time between updates.

## Keywords
* `ac, am, as, scheduler, offset, equalaspect, scatterkwargs`: propagated to [`abm_plot`](@ref).
* `spu = 1:100`: The values of the "spu" slider.
"""
function abm_play(model, agent_step!, model_step!; kwargs...)
    figure = Figure(; resolution = (600, 700), backgroundcolor = DEFAULT_BG)
    abm_play!(figure, model, agent_step!, model_step!; kwargs...)
    return figure
end

function abm_play!(figure, model, agent_step!, model_step!; spu = 1:100, kwargs...)
    # preinitialize a bunch of stuff
    model0 = deepcopy(model)
    modelobs = Observable(model) # only useful for resetting
    ac = get(kwargs, :ac, JULIADYNAMICS_COLORS[1])
    as = get(kwargs, :as, 10)
    am = get(kwargs, :am, :circle)
    scheduler = get(kwargs, :scheduler, model.scheduler)
    offset = get(kwargs, :offset, nothing)
    # plot the abm
    abmax = figure[1,1] = Axis(figure)
    pos, colors, sizes, markers = abm_plot!(abmax, model; kwargs...)
    # create the controls for the GUI
    speed, slep, run, reset, = abm_controls_play!(figure, model, spu, false)
    # Functionality of pressing the run button
    isrunning = Observable(false)
    on(run) do clicks; isrunning[] = !isrunning[]; end
    on(run) do clicks
        @async while isrunning[]
        # while isrunning[]
            n = speed[]
            model = modelobs[] # this is useful only for the reset button
            abm_interactive_stepping(
                model, agent_step!, model_step!, n, scheduler,
                pos, colors, sizes, markers, ac, as, am, offset
            )
            slep[] == 0 ? yield() : sleep(slep[])
            isopen(figure.scene) || break # crucial, ensures computations stop if closed window.
        end
    end
    # Clicking the reset button
    on(reset) do clicks
        modelobs[] = deepcopy(model0)
        update_abm_plot!(pos, colors, sizes, markers, model0, scheduler(model0), ac, as, am, offset)
    end

    return nothing
end

function abm_controls_play!(figure, model, spu, add_update = false)
    controllayout = figure[2, 1] = GridLayout(tellheight = true)
    spusl = labelslider!(figure, "spu =", spu; tellwidth = true)
    if model.space isa Agents.ContinuousSpace
        _s, _v = 0:0.01:1, 0
    else
        _s, _v = 0:0.1:10, 1
    end
    slesl = labelslider!(figure, "sleep =", _s, sliderkw = Dict(:startvalue => _v))
    controllayout[1, :] = spusl.layout
    controllayout[2, :] = slesl.layout
    run = Button(figure, label = "run")
    reset = Button(figure, label = "reset")
    if add_update
        update = Button(figure, label = "update")
        controllayout[3, :] = MakieLayout.hbox!(run, reset, update; tellwidth = false)
        upret = update.clicks
    else
        upret = nothing
        controllayout[3, :] = MakieLayout.hbox!(run, reset; tellwidth = false)
    end
    return spusl.slider.value, slesl.slider.value, run.clicks, reset.clicks, upret
end

function abm_interactive_stepping(
        model, agent_step!, model_step!, n, scheduler,
        pos, colors, sizes, markers, ac, as, am, offset
    )
    Agents.step!(model, agent_step!, model_step!, n)
    ids = scheduler(model)
    update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am, offset)
    return nothing
end

function update_abm_plot!(
        pos, colors, sizes, markers, model, ids, ac, as, am, offset
    )
    if Agents.nagents(model) == 0
        @warn "The model has no agents, we can't plot anymore!"
        error("The model has no agents, we can't plot anymore!")
    end
    if offset == nothing
        pos[] = [model[i].pos for i in ids]
    else
        pos[] = [model[i].pos .+ offset(model[i]) for i in ids]
    end
    if ac isa Function; colors[] = to_color.([ac(model[i]) for i in ids]); end
    if as isa Function; sizes[] = [as(model[i]) for i in ids]; end
    if am isa Function; markers[] = [am(model[i]) for i in ids]; end
end


"""
    abm_play(file, model, agent_step!, model_step!; kwargs...)
This function exports the animated time evolution of an agent based model into a video
saved at given path `file`. The plotting is identical as in [`abm_plot`](@ref).

## Keywords
* `ac, am, as, scheduler, offset, equalaspect, scatterkwargs`: propagated to [`abm_plot`](@ref).
* `spf = 1`: Steps-per-frame, i.e. how many times to step the model before recording a new
  frame.
* `framerate = 30`: The frame rate of the exported video.
* `frames = 300`: How many frames to record in total.
* `resolution = (600, 600)`: Resolution of the figure.
"""
function abm_video(file, model, agent_step!, model_step!;
        spf = 1, framerate = 30, frames = 300, resolution = (600, 600),
        title = "", showstep = true, kwargs...
    )
    figure = Figure(; resolution, backgroundcolor = DEFAULT_BG)
    # preinitialize a bunch of stuff
    model0 = deepcopy(model)
    modelobs = Observable(model) # only useful for resetting
    ac = get(kwargs, :ac, JULIADYNAMICS_COLORS[1])
    as = get(kwargs, :as, 10)
    am = get(kwargs, :am, :circle)
    scheduler = get(kwargs, :scheduler, model.scheduler)
    offset = get(kwargs, :offset, nothing)

    # add some title stuff
    s = Observable(0) # counter of current step
    if title ≠ "" && showstep
        t = lift(x -> title*", step = "*string(x), s)
    elseif showstep
        t = lift(x -> "step = "*string(x))
    else
        t = title
    end

    # plot the abm
    abmax = figure[1,1] = Axis(figure; title = t, titlealign = :left)
    pos, colors, sizes, markers = abm_plot!(abmax, model; kwargs...)


    record(figure, file, 1:frames; framerate) do j
        abm_interactive_stepping(
            model, agent_step!, model_step!, spf, scheduler,
            pos, colors, sizes, markers, ac, as, am, offset
        )
        s[] += spf; s[] = s[]
        # (title ≠ "" || showstep) && (abmax.title = titlef(s))
    end
    return nothing
end
