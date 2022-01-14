#=
In this file we define how agents are plotted and how the plots are updated while stepping
=#
# TODO: I should check whether it is worth to type-parameterize this.
struct ABMStepper # {X, C, M, S, O, AC, AS, AM, HA}
    ac # ::C
    am # ::M
    as # ::S
    offset # ::O
    scheduler # ::X
    pos # ::Observable
    colors # ::AC
    sizes # ::AS
    markers # ::AM
    heatarray # ::HA
    heatobs # ::HO
end

Base.show(io::IO, ::ABMStepper) =
println(io, "Helper structure for stepping and updating the plot of an agent based model. ",
"It is outputted by `abm_plot` and can be used in `Agents.step!`, see `abm_plot`.")

"Initialize the abmstepper and the plotted observables. Return the stepper."
function abm_init_stepper(model; ac, am, as, scheduler, offset, heatarray)

    if !isnothing(heatarray)
        # TODO: This is also possible for continuous spaces, we have to
        # get the matrix size, and then make a range for each dimension
        # and do heatmap!(ax, x, y, heatobs)
        #
        # TODO: use surface!(heatobs) here?
        matrix = Agents.get_data(model, heatarray, identity)
        if !(matrix isa AbstractMatrix) || size(matrix) ≠ size(model.space)
            error("The heat array property must yield a matrix of same size as the grid!")
        end
        heatobs = Observable(matrix)
    else
        heatobs = nothing
    end

    ids = scheduler(model)
    colors = Observable(ac isa Function ? to_color.([ac(model[i]) for i ∈ ids]) : to_color(ac))
    sizes = Observable(as isa Function ? [as(model[i]) for i ∈ ids] : as)
    markers = Observable(am isa Function ? [am(model[i]) for i ∈ ids] : am)
    pos = Observable(agents_pos_for_plotting(model, offset, ids))
    if user_used_polygons(am, markers)
        if am isa Function
            markers[] = [translate(m, p) for (m, p) in zip(markers[], pos[])]
        else
            markers[] = [translate(am, p) for p in pos[]]
        end
        # For polygons we always need vector, even if all agents are same polygon
    end

    return ABMStepper(
        ac, am, as, offset, scheduler,
        pos, colors, sizes, markers,
        heatarray, heatobs
    )
end

function agents_pos_for_plotting(model, offset, ids)
    if model.space isa Agents.OpenStreetMapSpace
        if isnothing(offset)
            pos = [Point2f0(Agents.OSM.lonlat(model[i].pos, model)) for i in ids]
        else
            pos = [Point2f0(Agents.OSM.lonlat(model[i].pos, model) .+ offset(model[i])) for i ∈ ids]
        end
        return pos
    end
    # standard space case
    postype = agents_space_dimensionality(model.space) == 3 ? Point3f0 : Point2f0
    if isnothing(offset)
        pos = [postype(model[i].pos) for i ∈ ids]
    else
        pos = [postype(model[i].pos .+ offset(model[i])) for i ∈ ids]
    end
    return pos
end

agents_pos_for_plotting(abms::ABMStepper, model, ids = abms.scheduler(model)) = 
agents_pos_for_plotting(model, abms.offset, ids)

agents_space_dimensionality(abm::Agents.ABM) = agents_space_dimensionality(abm.space)
agents_space_dimensionality(::Agents.GridSpace{D}) where {D} = D
agents_space_dimensionality(::Agents.ContinuousSpace{D}) where {D} = D
agents_space_dimensionality(::Agents.OpenStreetMapSpace) = 2

SUPPORTED_AGENTS_SPACES =  Union{
    Agents.DiscreteSpace,
    Agents.ContinuousSpace,
    Agents.OpenStreetMapSpace,
}

"Initialize the ABM plot and return it."
function abm_init_plot!(ax, model, abmstepper::ABMStepper;
        heatkwargs, add_colorbar, static_preplot!, scatterkwargs
    )

    @assert typeof(model.space) <: SUPPORTED_AGENTS_SPACES
    plot_agents_space!(ax, model)

    if !isnothing(abmstepper.heatobs)
        heatkwargs = merge((colormap=JULIADYNAMICS_CMAP,), heatkwargs)
        hmap = heatmap!(ax, abmstepper.heatobs[]; heatkwargs...)
        if add_colorbar 
            fig = ax.parent
            Colorbar(fig[1, 1][1, 2], hmap, width = 20)
        end
        # rowsize!(fig[1,1].fig.layout, 1, ax.scene.px_area[].widths[2]) # Colorbar height = axis height
    end

    static_plot = static_preplot!(ax, model)
    !isnothing(static_plot) && (static_plot.inspectable[] = false)

    # Here we make the decision of whether the user has provided markers, and thus use
    # `scatter`, or polygons, and thus use `poly`:
    if user_used_polygons(abmstepper.am, abmstepper.markers)
        poly!(ax, abmstepper.markers; color = abmstepper.ac, scatterkwargs...)
    else
        scatter!(ax, abmstepper.pos; 
            color = abmstepper.colors, marker = abmstepper.markers, 
            markersize = abmstepper.sizes, scatterkwargs...
        )
    end
    return
end


"Plot space and/or set axis limits."
function plot_agents_space!(ax, model)
    if model.space isa Agents.OpenStreetMapSpace
        Main.OSMMakie.osmplot!(ax, model.space.map)
        return
    end
    if model.space isa Agents.ContinuousSpace
        e = model.space.extent
    elseif model.space isa Agents.DiscreteSpace
        e = size(model.space.s) .+ 1
    end
    o = zero.(e)
    xlims!(ax, o[1], e[1])
    ylims!(ax, o[2], e[2])
    is3d = length(o) == 3
    is3d && zlims!(ax, o[3], e[3])
    return
end

default_static_preplot(ax, model) = nothing

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
    pos, colors = abmstepper.pos, abmstepper.colors
    sizes, markers =  abmstepper.sizes, abmstepper.markers

    Agents.step!(model, agent_step!, model_step!, n)

    if Agents.nagents(model) == 0
        @warn "The model has no agents"
    end
    ids = abmstepper.scheduler(model)
    pos[] = agents_pos_for_plotting(abmstepper, model, ids)
    if ac isa Function; colors[] = to_color.([ac(model[i]) for i in ids]); end
    if as isa Function; sizes[] = [as(model[i]) for i in ids]; end
    if am isa Function; markers[] = [am(model[i]) for i in ids]; end
    # If we use Polygons as markers, do a final update:
    if user_used_polygons(am, markers)
        if am isa Function
            markers[] = [translate(m, p) for (m, p) in zip(markers[], pos[])]
        else
            markers[] = [translate(am, p) for p in pos[]]
        end
    end
    # Finally update the heat array, if any
    if !isnothing(abmstepper.heatarray)
        newmatrix = Agents.get_data(model, abmstepper.heatarray, identity)
        abmstepper.heatobs[] = newmatrix
    end
    return nothing
end
