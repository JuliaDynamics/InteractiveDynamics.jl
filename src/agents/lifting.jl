#=
In this file we define how agents are plotted and how the plots are updated while stepping
=#

function lift_attributes(model, ac, as, am, offset, heatarray, used_poly)
    ids = @lift(abmplot_ids($model))
    pos = @lift(abmplot_pos($model, $offset, $ids))
    color = @lift(abmplot_colors($model, $ac, $ids))
    marker = @lift(abmplot_marker($model, used_poly, $am, $pos, $ids))
    markersize = @lift(abmplot_markersizes($model, $as, $ids))
    heatobs = @lift(abmplot_heatobs($model, $heatarray))

    return pos, color, marker, markersize, heatobs
end

abmplot_ids(model::Agents.ABM{<:SUPPORTED_SPACES}) = Agents.allids(model)
abmplot_ids(model::Agents.ABM{<:Agents.GraphSpace}) = eachindex(model.space.stored_ids)

function abmplot_pos(model::Agents.ABM{<:SUPPORTED_SPACES}, offset, ids)
    postype = agents_space_dimensionality(model.space) == 3 ? Point3f : Point2f
    if isnothing(offset)
        return [postype(model[i].pos) for i in ids]
    else
        return [postype(model[i].pos .+ offset(model[i])) for i in ids]
    end
end

function abmplot_pos(model::Agents.ABM{<:Agents.OpenStreetMapSpace}, offset, ids)
    if isnothing(offset)
        return [Point2f(Agents.OSM.lonlat(model[i].pos, model)) for i in ids]
    else
        return [Point2f(Agents.OSM.lonlat(model[i].pos, model) .+ offset(model[i])) for i in ids]
    end
end

abmplot_pos(model::Agents.ABM{<:Agents.GraphSpace}, offset, ids) = nothing

agents_space_dimensionality(abm::Agents.ABM) = agents_space_dimensionality(abm.space)
agents_space_dimensionality(::Agents.AbstractGridSpace{D}) where {D} = D
agents_space_dimensionality(::Agents.ContinuousSpace{D}) where {D} = D
agents_space_dimensionality(::Agents.OpenStreetMapSpace) = 2
agents_space_dimensionality(::Agents.GraphSpace) = 2

abmplot_colors(model::Agents.ABM{<:SUPPORTED_SPACES}, ac, ids) = to_color(ac)
abmplot_colors(model::Agents.ABM{<:SUPPORTED_SPACES}, ac::Function, ids) = 
    to_color.([ac(model[i]) for i in ids])
abmplot_colors(model::Agents.ABM{<:Agents.GraphSpace}, ac::Function, ids) = 
    to_color.([ac(model, idx) for idx in ids])

function abmplot_marker(model::Agents.ABM{<:SUPPORTED_SPACES}, used_poly, am, pos, ids)
    marker = am
    # need to update used_poly Observable here for inspection
    used_poly[] = user_used_polygons(am, marker)
    if used_poly[] # for polygons we always need vector, even if all agents are same polygon
        marker = [translate(am, p) for p in pos]
    end
    return marker
end

function abmplot_marker(model::Agents.ABM{<:SUPPORTED_SPACES}, used_poly, am::Function, pos, ids)
    marker = [am(model[i]) for i in ids]
    # need to update used_poly Observable here for use with inspection
    used_poly[] = user_used_polygons(am, marker)
    if used_poly[]
        marker = [translate(m, p) for (m, p) in zip(marker, pos)]
    end
    return marker
end

# TODO: Add support for polygon markers for GraphSpace if possible with GraphMakie
abmplot_marker(model::Agents.ABM{<:Agents.GraphSpace}, used_poly, am, pos, ids) = am
abmplot_marker(model::Agents.ABM{<:Agents.GraphSpace}, used_poly, am::Function, pos, ids) = 
    [am(model, idx) for idx in ids]

user_used_polygons(am, marker) = false
user_used_polygons(am::Polygon, marker) = true
user_used_polygons(am::Function, marker::Vector{<:Polygon}) = true

abmplot_markersizes(model::Agents.ABM{<:SUPPORTED_SPACES}, as, ids) = as
abmplot_markersizes(model::Agents.ABM{<:SUPPORTED_SPACES}, as::Function, ids) =
    [as(model[i]) for i in ids]

abmplot_markersizes(model::Agents.ABM{<:Agents.GraphSpace}, as, ids) = as
abmplot_markersizes(model::Agents.ABM{<:Agents.GraphSpace}, as::Function, ids) = 
    [as(model, idx) for idx in ids]

function abmplot_heatobs(model, heatarray)
    heatobs = begin
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
            matrix
        else
            nothing
        end
    end
    return heatobs
end

abmplot_edge_color(model, ec) = to_color(ec)
abmplot_edge_color(model, ec::Function) = to_color.(ec(model))

abmplot_edge_width(model, ew) = ew
abmplot_edge_width(model, ew::Function) = ew(model)
