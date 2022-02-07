export abm_data_exploration, abm_video

"""
    abm_data_exploration(model::ABM; alabels, mlabels, kwargs...)

Open an interactive application for exploring an agent based model and
the impact of changing parameters on the time evolution. Requires `Agents`.

The application evolves an ABM interactively and plots its evolution, while allowing 
changing any of the model parameters interactively and also showing the evolution of 
collected data over time (if any are asked for, see below).
The agent based model is plotted and animated exactly as in [`abmplot`](@ref),
and the `model` argument as well as splatted `kwargs` are propagated there as-is.
This convencience function *only works for aggregated agent data*.

Calling `abm_data_exploration` returns: `fig::Figure, p::ABMPlot`. So you can save and/or 
further modify the figure. But it is also possible to access the collected data (if any) 
via the plot object, just like in the case of using [`abmplot`](@ref) directly.

Clicking the "reset" button will add a red vertical line to the data plots for visual 
guidance.

## Keywords arguments (in addition to those in `abmplot`)
* `alabels, mlabels`: If data are collected from agents or the model with `adata, mdata`,
  the corresponding plots' y-labels are automatically named after the collected data.
  It is also possible to provide `alabels, mlabels` (vectors of strings with exactly same 
  length as `adata, mdata`), and these labels will be used instead.
* `plotkwargs = NamedTuple()`: Keywords to customize the styling of the resulting 
  [`scatterlines`](https://makie.juliaplots.org/dev/examples/plotting_functions/scatterlines/index.html) plots.
"""
function abm_data_exploration(model; 
        alabels = nothing, mlabels = nothing, plotkwargs = NamedTuple(), kwargs...)
    fig = Figure(resolution = (1600, 800))
    ax = Axis(fig[1,1])
    p = abmplot!(model; ax, kwargs...)

    adata, mdata, adf, mdf = p.adata[], p.mdata[], p.adf[], p.mdf[] # alias Observables
    !isnothing(adata) && @assert eltype(adata)<:Tuple "Only aggregated agent data are allowed."
    !isnothing(alabels) && @assert length(alabels) == length(adata)
    !isnothing(mlabels) && @assert length(mlabels) == length(mdata)
    L = (isnothing(adata) ? 0 : size(adf)[2]-1) + (isnothing(mdata) ? 0 : size(mdf)[2]-1)

    init_abm_data_plots!(fig, p, adata, mdata, alabels, mlabels, plotkwargs)

    return fig, p
end

function init_abm_data_plots!(fig, p, adata, mdata, alabels, mlabels, plotkwargs)
    La = isnothing(adata) ? 0 : size(p.adf[])[2]-1
    Lm = isnothing(mdata) ? 0 : size(p.mdf[])[2]-1
    La + Lm == 0 && return nothing # failsafe; don't add plots if dataframes are empty

    plotlayout = fig[:, end+1] = GridLayout(tellheight = false)
    axs = []

    for i in 1:La # add adata plots
        y_label = string(adata[i][2]) * "_" * string(adata[i][1])
        points = @lift(Point2f.($(p.adf).step, $(p.adf)[:,y_label]))
        ax = plotlayout[i, :] = Axis(fig)
        push!(axs, ax)
        ax.ylabel = isnothing(alabels) ? y_label : alabels[i]
        c = JULIADYNAMICS_COLORS[mod1(i, 3)]
        scatterlines!(ax, points;
            marker = MARKER, markersize = 5Makie.px, color = c,
            strokecolor = c, strokewidth = 0.5,
            label = ax.ylabel, plotkwargs...
        )
    end

    for i in 1:Lm # add mdata plots
        y_label = string(mdata[i])
        points = @lift(Point2f.($(p.mdf).step, $(p.mdf)[:,y_label]))
        ax = plotlayout[i+La, :] = Axis(fig)
        push!(axs, ax)
        ax.ylabel = isnothing(mlabels) ? y_label : mlabels[i]
        c = JULIADYNAMICS_COLORS[mod1(i+La, 3)]
        scatterlines!(ax, points;
            marker = MARKER, markersize = 5Makie.px, color = c,
            strokecolor = c, strokewidth = 0.5,
            label = ax.ylabel, plotkwargs...
        )
    end

    if La+Lm > 1
        for ax in @view(axs[1:end-1]); hidexdecorations!(ax, grid = false); end
    end
    axs[end].xlabel = "step"
    
    return nothing
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
* `figurekwargs = NamedTuple()`: Figure related keywords (e.g. resolution, backgroundcolor).
* `axiskwargs = NamedTuple()`: Axis related keywords (e.g. aspect).
* `kwargs...`: All other keywords are propagated to [`abmplot`](@ref).
"""
function abm_video(file, model, agent_step!, model_step! = Agents.dummystep;
            spf = 1, framerate = 30, frames = 300,  title = "", showstep = true,
            figurekwargs = NamedTuple(), axiskwargs = NamedTuple(), kwargs...)
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

    fig = Figure(; resolution = (600,600), backgroundcolor = DEFAULT_BG, figurekwargs...)
    ax = fig[1,1][1,1] = agents_space_dimensionality(model) == 3 ? 
        Axis3(fig; axiskwargs...) : Axis(fig; axiskwargs...)
    abmplot!(model; ax, kwargs...)

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
