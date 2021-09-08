"Define ABMPlot plotting function with some attribute defaults."
@recipe(ABMPlot, pos, model) do scene
    Theme(
        # insert InteractiveDynamics theme here?   
    )
    Attributes(
        ac = JULIADYNAMICS_COLORS[1],
        as = 10,
        am = :circle,
        scatterkwargs = NamedTuple(),
    )
end

# 2D space
function Makie.plot!(abmplot::ABMPlot{<:Tuple{Vector{Point2f0}, <:Agents.ABM}})
    scatter!(abmplot, abmplot[:pos];
        color=abmplot[:ac], marker=abmplot[:am], markersize=abmplot[:as],
        abmplot[:scatterkwargs]...
    )
    return abmplot
end

# 3D space
function Makie.plot!(abmplot::ABMPlot{<:Tuple{Vector{Point3f0}, <:Agents.ABM}})
    meshscatter!(abmplot, abmplot[:pos];
        color=abmplot[:ac], marker=abmplot[:am], markersize=abmplot[:as],
        abmplot[:scatterkwargs]...
    )
    return abmplot
end

# TODO: Add poly plotting method

##########################################################################################
# Agent inspection on mouse hover
##########################################################################################

function Makie.show_data(inspector::DataInspector, 
            plot::ABMPlot{<:Tuple{Vector{Point2f0}, <:Agents.ABM}},
            idx, ::Scatter)
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f0, plot[1][][idx], 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    as = plot.as[]

    pos = (plot[1][][idx].data[1], plot[1][][idx].data[2])
    s = typeof(plot.model[].space)
    if s <: Agents.ContinuousSpace
        pos = Float64.(pos)
    elseif s <: Agents.GridSpace
        pos = Int.(pos)
    end
    a._display_text[] = agent2string(plot.model[], pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* as .- Vec2f0(5), Vec2f0(as) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

# TODO: Properly implement 3D version
# TODO: Test 3D version
function Makie.show_data(inspector::DataInspector, 
            plot::ABMPlot{<:Tuple{Vector{Point3f0}, <:Agents.ABM}},
            idx, ::Scatter)
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f0, plot[1][][idx], 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    as = plot.as[]

    pos = (plot[1][][idx].data[1], plot[1][][idx].data[2], plot[1][][idx].data[3])
    s = typeof(plot.model[].space)
    if s <: Agents.ContinuousSpace
        pos = Float64.(pos)
    elseif s <: Agents.GridSpace
        pos = Int.(pos)
    end
    a._display_text[] = agent2string(plot.model[], pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* as .- Vec2f0(5), Vec2f0(as) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

# TODO: Add poly show_data method
# TODO: Test 2D model with polygons

"""
Convert agent data into a string.

Concatenate strings if there are multiple agents at given `pos`.
"""
function agent2string(model::Agents.ABM, pos::NTuple{2, Int})
    ids = Agents.ids_in_position(pos, model)
    s = ""
    for id in ids
        s *= agent2string(model[id]) * "\n"
    end
    return s
end

function agent2string(model::Agents.ABM, pos::NTuple{2, Float64})
    ids = Agents.nearby_ids(pos, model, 0.01)
    s = ""
    for id in ids
        s *= agent2string(model[id]) * "\n"
    end
    return s
end

function agent2string(agent::A) where {A<:Agents.AbstractAgent}
    agentstring = "▶ $(nameof(A))\n"
    
    for field in fieldnames(A)
        if field != :pos
            agentstring *= "$(field): $(getproperty(agent, field))\n"
        else
            if typeof(field) == DiscretePos
                agent_pos = getproperty(agent, field)
            else 
                agent_pos = round.(getproperty(agent, field), digits=2)
            end
            agentstring *= "$(field): $agent_pos\n"
        end
    end
    
    return agentstring
end
