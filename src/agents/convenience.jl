export abm_data_exploration, abm_video

"""
    abm_data_exploration(model::ABM; alabels, mlabels, kwargs...)

Open an interactive application for exploring an agent based model and
the impact of changing parameters on the time evolution. Requires `Agents`.
The application evolves an ABM interactively and plots its evolution, while allowing
changing any of the model parameters interactively and also
showing the evolution of collected data over time (if any are asked for, see below).
The agent based model is plotted and animated exactly as in [`abm_play`](@ref),
and the arguments `model, agent_step!, model_step!` are propagated there as-is.
Calling `abm_data_exploration` returns: `fig, agent_df, model_df`. So you can save the
figure, but you can also access the collected data (if any).

## Interaction
The "reset" button resets the model to its original agent and space state but it updates
it to the currently selected parameter values. A red vertical line is displayed in the
data plots when resetting, for visual guidance.

## Keywords arguments (in addition to those in `abmplot`)
* `alabels, mlabels`: If data are collected from agents or the model with `adata, mdata`,
  the corresponding plots' y-labels are automatically named after the collected data.
  It is also possible to provide `alabels, mlabels` (vectors of strings with exactly same 
  length as `adata, mdata`), and these labels will be used instead.
"""
function abm_data_exploration(model; alabels = nothing, mlabels = nothing, kwargs...)
    fig = Figure(1600, 800)
    ax = Axis(fig[1,1])
    p = abmplot!(model; ax, kwargs...)

    return fig, p
end


##########################################################################################
"""
    abm_video(file, model, agent_step! [, model_step!]; kwargs...)
This function exports the animated time evolution of an agent based model into a video
saved at given path `file`, by recording the behavior of the interactive version of 
[`abmplot`](@ref) (without sliders).
The plotting is identical as in [`abmplot`](@ref) and applicable keywords are propagated.

## Keywords
* `spf = 1`: Steps-per-frame, i.e. how many times to step the model before recording a new
  frame.
* `framerate = 30`: The frame rate of the exported video.
* `frames = 300`: How many frames to record in total, including the starting frame.
* `title = ""`: The title of the figure.
* `showstep = true`: If current step should be shown in title.
* `kwargs...`: All other keywords are propagated to [`abm_plot`](@ref).
"""
function abm_video(file, model, agent_step!, model_step! = Agents.dummystep;
            spf = 1, framerate = 30, frames = 300,  title = "", showstep = true,
            resolution = (600,600), backgroundcolor = DEFAULT_BG,
            axiskwargs = NamedTuple(), kwargs...)
    # add some title stuff
    s = Observable(0) # counter of current step
    if title ≠ "" && showstep
        t = lift(x -> title*", step = "*string(x), s)
    elseif showstep
        t = lift(x -> "step = "*string(x), s)
    else
        t = title
    end
    axiskwargs = (title = t, titlealign = :left, axiskwargs...)

    fig = Figure(; resolution, backgroundcolor)
    ax = fig[1,1][1,1] = agents_space_dimensionality(model) == 3 ? 
        Axis3(fig; axiskwargs...) : Axis(fig; axiskwargs...)
    modelobs = Observable(model)
    abmplot!(modelobs; ax, kwargs...)

    record(fig, file; framerate) do io
        for j in 1:frames-1
            recordframe!(io)
            Agents.step!(model, agent_step!, model_step!, spf)
            modelobs[] = modelobs[]
            s[] += spf; s[] = s[]
        end
        recordframe!(io)
    end
    return nothing
end
