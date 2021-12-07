export abm_data_exploration

"""
    abm_data_exploration(model::ABM, agent_step!, model_step!, params=Dict(); kwargs...)
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
Besides the basic time evolution interaction of [`abm_play`](@ref), additional
functionality here allows changing model parameters in real time, based on the provided
fourth argument `params`. This is a dictionary which decides which
parameters of the model will be configurable from the interactive application.
Each entry of `params` is a pair of `Symbol` to an `AbstractVector`, and provides a range
of possible values for the parameter named after the given symbol (see example online).
Changing a value in the parameter slides is only updated into the actual model when
pressing the "update" button.

The "reset" button resets the model to its original agent and space state but it updates
it to the currently selected parameter values. A red vertical line is displayed in the
data plots when resetting, for visual guidance.

## Keywords

* `ac, am, as, scheduler, offset, aspect, scatterkwargs`: propagated to [`abm_plot`](@ref).
* `adata, mdata`: Same as the keyword arguments of `Agents.run!`, and decide which data of the
  model/agents will be collected and plotted below the interactive plot. Notice that
  data collection can only occur on plotted steps (and thus steps not plotted due to
  "spu" are also not data-collected).
* `alabels, mlabels`: If data are collected from agents or the model with `adata, mdata`,
  the corresponding plots have a y-label named after the collected data. Instead, you can
  give `alabels, mlabels` (vectors of strings with exactly same length as `adata, mdata`),
  and these labels will be used instead.
* `when = true`: When to perform data collection, as in `Agents.run!`.
* `spu = 1:100`: Values that the "spu" slider will obtain.
"""
function abm_data_exploration(
    model, agent_step!, model_step!, params = Dict();
    adata = nothing,
    mdata = nothing,
    alabels = nothing,
    mlabels = nothing,
    when = true,
    spu = 1:100,
    colorscheme = JULIADYNAMICS_COLORS,
    kwargs...
)

    # Initialize main layout
    fig, abmstepper = abm_plot(model; resolution = (1600, 800), colorscheme, kwargs...)

    # Initialize agent and model dataframes
    adf = Agents.init_agent_dataframe(model, adata)
    mdf = Agents.init_model_dataframe(model, mdata)

    # Initialize data plots and define button behavior
    abm_data_exploration!(fig, abmstepper, model, agent_step!, model_step!, params;
        spu, when, adata, mdata, alabels, mlabels, adf, mdf, colorscheme
    )

    display(fig)
    return fig, adf, mdf
end

function abm_data_exploration!(
    fig, abmstepper, model, agent_step!, model_step!, params;
    spu, when, adata, mdata, alabels, mlabels, adf, mdf, colorscheme
)
    # preinitialize a bunch of stuff
    model0 = deepcopy(model)
    modelobs = Observable(model) # only useful for resetting

    !isnothing(adata) && @assert adata[1] isa Tuple "Only aggregated agent data are allowed."
    !isnothing(alabels) && @assert length(alabels) == length(adata)
    !isnothing(mlabels) && @assert length(mlabels) == length(mdata)
    L = (isnothing(adata) ? 0 : size(adf)[2] - 1) + (isnothing(mdata) ? 0 : size(mdf)[2] - 1)
    s = 0 # current step

    speed, slep, step, run, reset, clear, update = abm_controls!(fig, model, spu, true)

    # Initialize parameter controls & data plots
    datalayout = fig[:, 2] = GridLayout(tellheight = false)
    slidervals = init_abm_param_controls!(fig, datalayout, model, params, L)
    if L > 0
        N = Observable([0]) # steps that data are recorded at.
        data, axs = init_abm_data_plots!(fig, datalayout, model, adf, mdf,
            adata, mdata, N, alabels, mlabels, colorscheme)
    end

    # Clicking the "step" button
    on(step) do clicks
        n = speed[]
        model = modelobs[] # necessary after resetting the model
        Agents.step!(abmstepper, model, agent_step!, model_step!, n)
        if L > 0
            s += n
            if L > 0 && Agents.should_we_collect(s, model, when) # update collected data
                push!(N.val, s)
                update_abm_data_plots!(data, axs, model, adf, mdf, adata, mdata, N)
            end
        end
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
        L > 0 && add_reset_line!(axs, s)
        update[] = update[] + 1 # trigger update button
    end

    # Clicking the "clear all" button
    on(clear) do clicks
        reset[] = reset[] + 1 # trigger reset button
        # empty!([adf, mdf])
        N[] = [0] # set new starting point for plots
        s = 0 # reset current step
        if L > 0
            for ax in axs
                delete!(ax)
            end
            data, axs = init_abm_data_plots!(fig, datalayout, model, adf, mdf,
                adata, mdata, N, alabels, mlabels, colorscheme)
        end
    end

    # Clicking the "update" button
    on(update) do clicks
        model = modelobs[]
        update_abm_properties!(model, slidervals)
    end

    return nothing
end

function init_abm_param_controls!(fig, datalayout, model, params, L)
    slidervals = Dict{Symbol,Observable}()
    for (i, (l, vals)) in enumerate(params)
        startvalue = has_key(model.properties, l) ?
                     get_value(model.properties, l) : vals[1]
        sll = labelslider!(fig, string(l), vals; sliderkw = Dict(:startvalue => startvalue))
        slidervals[l] = sll.slider.value # directly add the observable
        datalayout[i+L, :] = sll.layout
    end
    return slidervals
end

function init_abm_data_plots!(
    fig, datalayout, model, adf, mdf,
    adata, mdata, N, alabels, mlabels, colorscheme
)
    Agents.collect_agent_data!(adf, model, adata, 0)
    Agents.collect_model_data!(mdf, model, mdata, 0)
    La = isnothing(adata) ? 0 : size(adf)[2] - 1
    Lm = isnothing(mdata) ? 0 : size(mdf)[2] - 1
    data, axs = [], []

    # Plot all quantities
    # TODO: make scatter+line plot 1.
    for i = 1:La
        x = Agents.aggname(adata[i])
        val = Observable([adf[end, x]])
        push!(data, val)
        ax = datalayout[i, :] = Axis(fig)
        push!(axs, ax)
        ax.ylabel = isnothing(alabels) ? x : alabels[i]
        c = colorscheme[mod1(i, 3)]
        lines!(ax, N, val, color = c)
        scatter!(ax, N, val; marker = MARKER, markersize = 4Makie.px, color = c,
            strokewidth = 0.4)
    end
    for i = 1:Lm
        x = Agents.aggname(mdata[i])
        val = Observable([mdf[end, x]])
        push!(data, val)
        ax = datalayout[i+La, :] = Axis(fig)
        push!(axs, ax)
        ax.ylabel = isnothing(mlabels) ? x : mlabels[i]
        c = colorscheme[mod1(i + La, 3)]
        lines!(ax, N, val, color = c)
        scatter!(ax, N, val, marker = MARKER, markersize = 4Makie.px, color = c,
            strokewidth = 0.4)
    end
    if La + Lm > 1
        for ax in @view(axs[1:end-1])
            hidexdecorations!(ax, grid = false)
        end
    end
    axs[end].xlabel = "step"
    return data, axs
end

function update_abm_data_plots!(data, axs, model, adf, mdf, adata, mdata, N)
    Agents.collect_agent_data!(adf, model, adata, N[][end])
    Agents.collect_model_data!(mdf, model, mdata, N[][end])
    La = isnothing(adata) ? 0 : size(adf)[2] - 1
    Lm = isnothing(mdata) ? 0 : size(mdf)[2] - 1

    for i = 1:La
        o = data[i]
        x = Agents.aggname(adata[i])
        val = adf[end, x]
        push!(o[], val)
        o[] = o[] #update plot
    end
    for i = 1:Lm
        o = data[i+La]
        x = Agents.aggname(mdata[i])
        val = mdf[end, x]
        push!(o[], val)
        o[] = o[] #update plot
    end
    # TODO: Maybe we can optimize this by setting the limits ourselves (we have the data)
    for ax in axs
        autolimits!(ax)
    end
end

function update_abm_properties!(model, slidervals)
    for l in keys(slidervals)
        v = slidervals[l][]
        if has_key(model.properties, l)
            set_value!(model.properties, l, v)
        else
            throw(KeyError("$l"))
        end
    end
end

function add_reset_line!(axs, s)
    for ax in axs
        # vline!(ax, s; color = "#c41818")
        vlines!(ax, [s], color = "#c41818")
    end
end
