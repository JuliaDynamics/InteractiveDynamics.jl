#=
In this file we define how agents are plotted and how the plots are updated while stepping
=#

function lift_attributes(model, ac, as, am, offset, heatarray, used_poly)
    ids = @lift(Agents.allids($model))
    pos = @lift(abmplot_pos($model, $offset, $ids))
    color = @lift(abmplot_colors($model, $ac, $ids))
    marker = @lift(abmplot_markers($model, $used_poly, $am, $pos, $ids))
    markersize = @lift(abmplot_markersizes($model, $as, $ids))
    heatobs = @lift(abmplot_heatobs($model, $heatarray))

    return pos, color, marker, markersize, heatobs
end

# Do we have to exclude OpenStreetMapSpace here for this dispatch to work?
function abmplot_pos(model::Agents.ABM{<:SUPPORTED_SPACES}, offset, ids)
    postype = agents_space_dimensionality(model.space) == 3 ? Point3f : Point2f
    pos = begin
        if isnothing(offset)
            [postype(model[i].pos) for i in ids]
        else
            [postype(model[i].pos .+ offset(model[i])) for i in ids]
        end
    end
    return pos
end

function abmplot_pos(model::Agents.ABM{<:Agents.OpenStreetMapSpace}, offset, ids)
    pos = begin
        if isnothing(offset)
            [Point2f(Agents.OSM.lonlat(model[i].pos, model)) for i in ids]
        else
            [Point2f(Agents.OSM.lonlat(model[i].pos, model) .+ offset(model[i])) for i in ids]
        end
    end
    return pos
end

agents_space_dimensionality(abm::Agents.ABM) = agents_space_dimensionality(abm.space)
agents_space_dimensionality(::Agents.AbstractGridSpace{D}) where {D} = D
agents_space_dimensionality(::Agents.ContinuousSpace{D}) where {D} = D
agents_space_dimensionality(::Agents.OpenStreetMapSpace) = 2

function abmplot_colors(model, ac, ids)
    colors = begin
        if ac isa Function
            to_color.([ac(model[i]) for i in ids])
        else
            to_color(ac)
        end
    end
    return colors
end

function abmplot_markers(model, used_poly, am, pos, ids)
    markers = am isa Function ? [am(model[i]) for i in ids] : am
    used_poly = user_used_polygons(am, markers)
    if used_poly
        if am isa Function
            markers = [translate(m, p) for (m, p) in zip(markers, pos)]
        else # for polygons we always need vector, even if all agents are same polygon
            markers = [translate(am, p) for p in pos]
        end
    end
    return markers
end

function user_used_polygons(am, markers)
    if (am isa Polygon)
        return true
    elseif (am isa Function) && (markers isa Vector{<:Polygon})
        return true
    else
        return false
    end
end

function abmplot_markersizes(model, as, ids)
    markersizes = begin
        if as isa Function
            [as(model[i]) for i in ids]
        else
            as
        end
    end
    return markersizes
end

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
