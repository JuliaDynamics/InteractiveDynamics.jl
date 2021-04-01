#=
In this file we define how agents are plotted and how the plots are updated while stepping
=#
# TODO: Perhaps it is worth it to NOT specialize this struct to its fields
struct ABMStepper{X, C, M, S, O, AC, AS, AM, HA}
    ac::C
    am::M
    as::S
    offset::O
    scheduler::X
    pos::Observable
    colors::AC
    sizes::AS
    markers::AM
    heatarray::HA
end

Base.show(io::IO, ::ABMStepper) =
println(io, "Helper structure for stepping and updating the plot of an agent based model. ",
"It is outputted by `abm_plot` and can be used in `Agents.step!`, see `abm_plot`.")

"Initialize the abmstepper and the plotted observables. return the stepper"
function abm_init_stepper_and_plot!(ax, model;
        ac = JULIADYNAMICS_COLORS[1],
        as = 10,
        am = :circle,
        scheduler = model.scheduler,
        offset = default_offset(model),
        equalaspect = true,
        scatterkwargs = NamedTuple(),
        static_preplot! = default_static_preplot,
        heatarray = nothing,
        heatkwargs = (colormap=:tokyo,),
    )

    o, e = modellims(model) # TODO: extend to 3D
    @assert length(o) == 2 "At the moment only 2D spaces can be plotted."
    # TODO: once graph plotting is possible, this will be adjusted
    @assert typeof(model.space) <: Union{Agents.ContinuousSpace, Agents.DiscreteSpace}
    # TODO: Point2f0 must be replaced by 3D version in the future

    # TODO: This should be expanded into 3D (and also scale and stuff)
    xlims!(ax, o[1], e[1])
    ylims!(ax, o[2], e[2])
    equalaspect && (ax.aspect = AxisAspect(1))

    static_preplot!(ax, model)
    if heatarray isa AbstractMatrix
        obs_heat = Observable(heatarray)
        heatmap!(ax, obs_heat; heatkwargs...)
    elseif heatarray isa Observable
        obs_heat = heatarray
        heatmap!(ax, obs_heat; heatkwargs...)
    else
        obs_heat = nothing
    end

    ids = scheduler(model)
    colors  = ac isa Function ? Observable(to_color.([ac(model[i]) for i ∈ ids])) : to_color(ac)
    sizes   = as isa Function ? Observable([as(model[i]) for i ∈ ids]) : as
    markers = am isa Function ? Observable([am(model[i]) for i ∈ ids]) : am
    if isnothing(offset)
        pos = Observable(Point2f0[model[i].pos for i ∈ ids])
    else
        pos = Observable(Point2f0[model[i].pos .+ offset(model[i]) for i ∈ ids])
    end

    # Here we make the decision of whether the user has provided markers, and thus use
    # `scatter`, or polygons, and thus use `poly`:
    if user_used_polygons(am, markers)
        # For polygons we always need vector, even if all agents are same polygon
        if markers isa Observable
            markers[] = [translate(m, p) for (m, p) in zip(markers[], pos[])]
        else
            markers = Observable([translate(am, p) for p in pos])
        end
        poly!(ax, markers; color = colors, scatterkwargs...)
    else
        scatter!(
            ax, pos;
            color = colors, markersize = sizes, marker = markers, strokewidth = 0.0,
            scatterkwargs...
        )
    end

    return ABMStepper(ac, am, as, offset, scheduler, pos, colors, sizes, markers, obs_heat)
end

function default_offset(model)
    if model.space isa Agents.GridSpace
        x = 0 .* size(model.space) .- 0.5
        return a -> x
    else
        return nothing
    end
end

default_static_preplot(ax, model) = nothing

function modellims(model)
    if model.space isa Agents.ContinuousSpace
        e = model.space.extent
    elseif model.space isa Agents.DiscreteSpace
        e = size(model.space.s)
    end
    return zero.(e), e
end

function user_used_polygons(am, markers)
    if (am isa Polygon)
        return true
    elseif (am isa Function) && (markers[][1] isa Polygon)
        return true
    else
        return false
    end
end

#=
    Agents.step!(abmstepper, model, agent_step!, model_step!, n::Int)
Step the given `model` for `n` steps while also updating the plot that corresponds to it,
which is produced with the function [`abm_plot`](@ref).

You can still call this function with `n=0` to update the plot for a new `model`,
without doing any stepping.
=#
function Agents.step!(abmstepper::ABMStepper, model, agent_step!, model_step!, n)
    @assert (n isa Int) "Only stepping with integer `n` is possible with `abmstepper`."
    ac, am, as = abmstepper.ac, abmstepper.am, abmstepper.as
    offset = abmstepper.offset
    pos, colors = abmstepper.pos, abmstepper.colors
    sizes, markers =  abmstepper.sizes, abmstepper.markers

    Agents.step!(model, agent_step!, model_step!, n)

    if !isnothing(abmstepper.heatarray) # trigger update on the heatmap
        abmstepper.heatarray[] = abmstepper.heatarray[]
    end
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
    # If we use Polygons as markers, do a final update:
    if user_used_polygons(am, markers)
        # translate all polygons according to pos
        markers[] = [translate(m, p) for (m, p) in zip(markers[], pos[])]
    end
    return nothing
end
