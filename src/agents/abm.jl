export abm_plot
export abm_play
export abm_video

function abm_plot(model; kwargs...)
    figure = Figure()
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
    o, e = modellims(model)
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

function abm_play(model, agent_step!, model_step!; kwargs...)
    figure = Figure(resolution = (800, 800), backgroundcolor = DEFAULT_BG)
    abm_play!(figure, model, agent_step!, model_step!; kwargs...)
    return figure
end

function abm_play!(figure, model, agent_step!, model_step!; add_update = false, spu = 1:100, kwargs...)
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
    speed, slep, run, reset, = abm_controls_play!(figure, model, spu, add_update)
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
            slep[] == 0 ? yield() : sleep(sleslider[])
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

function abm_video(file, model, agent_step!, model_step!;
        spf = 1, framerate = 60, frames = 1000, kwargs...
    )
    figure = Figure(resolution = (800, 800), backgroundcolor = DEFAULT_BG)
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

    record(figure, file, 1:frames; framerate = framerate) do j
        abm_interactive_stepping(
            model, agent_step!, model_step!, spf, scheduler,
            pos, colors, sizes, markers, ac, as, am, offset
        )
    end
    return nothing
end
