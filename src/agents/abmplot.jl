##########################################################################################
# ABMPlot recipe
##########################################################################################

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
    abmplot.am[] == :circle && (abmplot.am = Sphere(Point3f0(0), 1))
    
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

    cursor_pos = (plot[1][][idx].data[1], plot[1][][idx].data[2])
    s = typeof(plot.model[].space)
    if s <: Agents.ContinuousSpace
        cursor_pos = Float64.(cursor_pos)
    elseif s <: Agents.GridSpace
        cursor_pos = Int.(cursor_pos)
    end
    a._display_text[] = agent2string(plot.model[], cursor_pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* as .- Vec2f0(5), Vec2f0(as) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

function Makie.show_data(inspector::DataInspector, 
            plot::ABMPlot{<:Tuple{Vector{Point3f0}, <:Agents.ABM}},
            idx, ::MeshScatter)
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f0, plot[1][][idx], 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    as = plot.as[]

    cursor_pos = (plot[1][][idx].data[1], plot[1][][idx].data[2], plot[1][][idx].data[3])
    s = typeof(plot.model[].space)
    if s <: Agents.ContinuousSpace
        cursor_pos = Float64.(cursor_pos)
    elseif s <: Agents.GridSpace
        cursor_pos = Int.(cursor_pos)
    end
    a._display_text[] = agent2string(plot.model[], cursor_pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* as .- Vec2f0(5), Vec2f0(as) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

# TODO: Add poly show_data method

DiscretePos = Union{NTuple{2, Int}, NTuple{3, Int}}
ContinuousPos = Union{NTuple{2, Float64}, NTuple{3, Float64}}

"""
Convert agent data into a string.

Concatenate strings if there are multiple agents at given `pos`.
"""
function agent2string(model::Agents.ABM, 
        cursor_pos::DiscretePos)
    ids = Agents.ids_in_position(cursor_pos, model)
    s = ""
    
    for id in ids
        s *= agent2string(model[id]) * "\n"
    end

    return s
end

function agent2string(model::Agents.ABM, 
        cursor_pos::ContinuousPos)
    ids = Agents.nearby_ids(cursor_pos, model, 0.01)
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
            agent_pos = getproperty(agent, field)
            if typeof(agent_pos) <: ContinuousPos
                agent_pos = round.(agent_pos, digits=2)
            end
            agentstring *= "$(field): $agent_pos\n"
        end
    end
    
    return agentstring
end
