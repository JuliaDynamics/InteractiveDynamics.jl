export abm_video

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
