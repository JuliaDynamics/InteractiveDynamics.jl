export abm_plot, abm_play, abm_video

"""
    abm_plot(model::ABM; kwargs...) → fig, abmstepper
Plot an agent based model by plotting each individual agent as a marker and using
the agent's position field as its location on the plot. Requires `Agents`.

Return the overarching `fig` object, as well as a struct `abmstepper` that can be used
to interactively animate the evolution of the ABM and combine it with other subplots.
To progress the ABM plot `n` steps simply do:
```julia
Agents.step!(abmstepper, model, agent_step!, model_step!, n)
```
You can still call this function with `n=0` to update the plot for a new `model`,
without doing any stepping.

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
* `resolution = (600, 600)`: Resolution of the fig.
"""
function abm_plot(model; resolution = (600, 600), kwargs...)
    fig = Figure(; resolution)
    ax = fig[1,1] = Axis(fig)
    abmstepper = abm_init_stepper_and_plot!(ax, model; kwargs...)
    return fig, abmstepper
end

##########################################################################################

"""
    abm_play(model, agent_step!, model_step!; kwargs...) → fig, abmstepper
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
function abm_play(model, agent_step!, model_step!; spu = 1:100, kwargs...)
    fig = Figure(; resolution = (600, 700), backgroundcolor = DEFAULT_BG)
    ax = fig[1,1] = Axis(fig)
    abmstepper = abm_init_stepper_and_plot!(ax, model; kwargs...)
    abm_play!(fig, abmstepper, model, agent_step!, model_step!; spu)
    display(fig)
    return fig, abmstepper
end

function abm_play!(fig, abmstepper, model, agent_step!, model_step!; spu)
    # preinitialize a bunch of stuff
    model0 = deepcopy(model)
    modelobs = Observable(model) # only useful for resetting
    speed, slep, run, reset, = abm_controls_play!(fig, model, spu, false)
    # Functionality of pressing the run button
    isrunning = Observable(false)
    on(run) do clicks; isrunning[] = !isrunning[]; end
    on(run) do clicks
        @async while isrunning[]
        # while isrunning[]
            n = speed[]
            model = modelobs[] # this is useful only for the reset button
            Agents.step!(abmstepper, model, agent_step!, model_step!, n)
            slep[] == 0 ? yield() : sleep(slep[])
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window.
        end
    end
    # Clicking the reset button
    on(reset) do clicks
        modelobs[] = deepcopy(model0)
        Agents.step!(abmstepper, modelobs[], agent_step!, model_step!, 0)
    end
    return nothing
end

function abm_controls_play!(fig, model, spu, add_update = false)
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
    run = Button(fig, label = "run")
    reset = Button(fig, label = "reset")
    if add_update
        update = Button(fig, label = "update")
        controllayout[3, :] = MakieLayout.hbox!(run, reset, update; tellwidth = false)
        upret = update.clicks
    else
        upret = nothing
        controllayout[3, :] = MakieLayout.hbox!(run, reset; tellwidth = false)
    end
    return spusl.slider.value, slesl.slider.value, run.clicks, reset.clicks, upret
end


##########################################################################################
"""
    abm_video(file, model, agent_step! [, model_step!]; kwargs...)
This function exports the animated time evolution of an agent based model into a video
saved at given path `file`, by recording the behavior of [`abm_play`](@ref) (without sliders).
The plotting is identical as in [`abm_plot`](@ref).

## Keywords
* `ac, am, as, scheduler, offset, equalaspect, scatterkwargs`: propagated to [`abm_plot`](@ref).
* `spf = 1`: Steps-per-frame, i.e. how many times to step the model before recording a new
  frame.
* `framerate = 30`: The frame rate of the exported video.
* `frames = 300`: How many frames to record in total.
* `resolution = (600, 600)`: Resolution of the fig.
"""
function abm_video(file, model, agent_step!, model_step! = Agents.dummystep;
        spf = 1, framerate = 30, frames = 300, resolution = (600, 600),
        title = "", showstep = true, kwargs...
    )

    # add some title stuff
    s = Observable(0) # counter of current step
    if title ≠ "" && showstep
        t = lift(x -> title*", step = "*string(x), s)
    elseif showstep
        t = lift(x -> "step = "*string(x), s)
    else
        t = title
    end

    fig = Figure(; resolution, backgroundcolor = DEFAULT_BG)
    ax = fig[1,1] = Axis(fig; title = t, titlealign = :left)
    abmstepper = abm_init_stepper_and_plot!(ax, model; kwargs...)

    record(fig, file, 1:frames; framerate) do j
        Agents.step!(abmstepper, model, agent_step!, model_step!, spf)
        s[] += spf; s[] = s[]
        # (title ≠ "" || showstep) && (abmax.title = titlef(s))
    end
    return nothing
end
