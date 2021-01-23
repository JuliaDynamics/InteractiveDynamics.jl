struct ABMStepper{X, C, M, S, O}
    ac::C
    am::M
    as::S
    offset::O
    scheduler::X
    pos::Observable
    colors::Observable
    sizes::Observable
    markers::Observable
end

Base.show(io::IO, ::ABMStepper) =
println(io, "Helper structure for stepping and updating the plot of an agent based model. ",
"It is outputted by `abm_plot` and can be used in `Agents.step!`.")

"Initialize the abmstepper and the plotted observables. return the stepper"
function abm_init_stepper_and_plot!(ax, model;
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
    # TODO: once graph plotting is possible, this will be adjusted
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
        ax, pos;
        color = colors, markersize = sizes, marker = markers, strokewidth = 0.0,
        scatterkwargs...
    )
    # TODO: This should be expanded into 3D
    xlims!(ax, o[1], e[1])
    ylims!(ax, o[2], e[2])
    equalaspect && (ax.aspect = AxisAspect(1))

    return ABMStepper(ac, am, as, offset, scheduler, pos, colors, sizes, markers)
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



#=
    Agents.step!(abmstepper, model, agent_step!, model_step!, n::Int)
Step the given `model` for `n` steps while also updating the plot that corresponds to it,
which is produced with the function [`abm_plot`](@ref).

You can still call this function with `n=0` to update the plot for a new `model`,
without doing any stepping.
=#
function Agents.step!(abmstepper::ABMStepper, model, agent_step!, model_step!, n::Int)
    ac, am, as = abmstepper.ac, abmstepper.am, abmstepper.as
    offset = abmstepper.offset
    pos, colors = abmstepper.pos, abmstepper.colors
    sizes, markers =  abmstepper.sizes, abmstepper.markers

    Agents.step!(model, agent_step!, model_step!, n)
    if Agents.nagents(model) == 0
        @warn "The model has no agents, we can't plot anymore!"
        error("The model has no agents, we can't plot anymore!")
    end
    ids = abmstepper.scheduler(model)
    if offset == nothing
        pos[] = [model[i].pos for i in ids]
    else
        pos[] = [model[i].pos .+ offset(model[i]) for i in ids]
    end
    if ac isa Function; colors[] = to_color.([ac(model[i]) for i in ids]); end
    if as isa Function; sizes[] = [as(model[i]) for i in ids]; end
    if am isa Function; markers[] = [am(model[i]) for i in ids]; end
    return nothing
end
