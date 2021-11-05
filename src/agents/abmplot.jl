export agent2string

##########################################################################################
# ABMPlot recipe
##########################################################################################

"Define ABMPlot plotting function with some attribute defaults."
@recipe(ABMPlot, agent_pos, model) do scene
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
    scatter!(abmplot, abmplot[:agent_pos];
        color=abmplot[:ac], marker=abmplot[:am], markersize=abmplot[:as],
        abmplot[:scatterkwargs]...
    )
    
    return abmplot
end

# 3D space
function Makie.plot!(abmplot::ABMPlot{<:Tuple{Vector{Point3f0}, <:Agents.ABM}})
    abmplot.am[] == :circle && (abmplot.am = Sphere(Point3f0(0), 1))
    
    meshscatter!(abmplot, abmplot[:agent_pos];
        color=abmplot[:ac], marker=abmplot[:am], markersize=abmplot[:as],
        abmplot[:scatterkwargs]...
    )
    
    return abmplot
end

# 2D polygons
function Makie.plot!(abmplot::ABMPlot{<:Tuple{Vector{<:Polygon{2}}, <:Agents.ABM}})
    poly!(abmplot, abmplot[:agent_pos];
        color=abmplot[:ac],
        abmplot[:scatterkwargs]...
    )
    
    return abmplot
end

##########################################################################################
# Agent inspection on mouse hover
##########################################################################################

# 2D space
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

# 3D space
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

# 2D polygons
# TODO: Fix this tooltip
function Makie.show_data(inspector::DataInspector, 
            plot::ABMPlot{<:Tuple{Vector{<:Polygon{2}}, <:Agents.ABM}},
            idx, ::Makie.Poly)
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

DiscretePos = Union{NTuple{2, Int}, NTuple{3, Int}}
ContinuousPos = Union{NTuple{2, Float64}, NTuple{3, Float64}}

function agent2string(model::Agents.ABM, cursor_pos::DiscretePos)
    ids = Agents.ids_in_position(cursor_pos, model)
    s = ""
    
    for id in ids
        s *= agent2string(model[id]) * "\n"
    end

    return s
end

function agent2string(model::Agents.ABM, cursor_pos::ContinuousPos)
    ids = Agents.nearby_ids(cursor_pos, model, 0.01)
    s = ""
    
    for id in ids
        s *= agent2string(model[id]) * "\n"
    end
    
    return s
end

"""
    agent2string(agent::A)
Convert agent data into a string which is used to display all agent variables and their 
values in the tooltip on mouse hover. Concatenates strings if there are multiple agents 
at one position.

Custom tooltips for agents can be implemented by adding a specialised method 
for `agent2string`.

Example:

```julia
import InteractiveDynamics.agent2string

function agent2string(agent::SpecialAgent)
    \"\"\"
    ✨ SpecialAgent ✨
    ID = \$(agent.id)
    Main weapon = \$(agent.charisma)
    Side weapon = \$(agent.pistol)
    \"\"\"
end
```
"""
function agent2string(agent::A) where {A<:Agents.AbstractAgent}
    agentstring = "▶ $(nameof(A))\n"
    
    agentstring *= "id: $(getproperty(agent, :id))\n"
    
    agent_pos = getproperty(agent, :pos)
    typeof(agent_pos) <: ContinuousPos && (agent_pos = round.(agent_pos, digits=2))
    agentstring *= "pos: $(agent_pos)\n"
    
    for field in fieldnames(A)[3:end]
        val = getproperty(agent, field)
        V = typeof(val)
        if V <: AbstractFloat
            val = round(val, digits=2)
        elseif V <: AbstractArray{<:AbstractFloat}
            val = round.(val, digits=2)
        elseif V <: Tuple && V <: NTuple{length(val), <:AbstractFloat}
            val = round.(val, digits=2)
        end
        agentstring *= "$(field): $val\n"
    end
    
    return agentstring
end
