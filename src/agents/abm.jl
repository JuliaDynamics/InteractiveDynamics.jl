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
        # The following keywords are useful for other source functions
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

    return pos # observable that is re-used by other source functions
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
