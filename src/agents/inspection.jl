##########################################################################################
# Agent inspection on mouse hover
#
# Note: This only works in combination with ABMPlot.
##########################################################################################

# 2D space
function Makie.show_data(inspector::DataInspector, 
    plot::ABMPlot{<:Tuple{<:Agents.ABM{<:GridOrContinuous}}}, idx, source::Scatter)
    if plot[:pos][] isa Vector{<:Polygon{2}}
        return show_data_poly(inspector, plot, idx, source)
    else
        return show_data_2D(inspector, plot, idx, source)
    end
end

function show_data_2D(inspector::DataInspector, 
            plot::ABMPlot{<:Tuple{<:Agents.ABM{<:S}}}, 
            idx, ::Scatter) where {S<:GridOrContinuous}
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f0, plot[:pos][][idx], 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    sizes = plot.sizes[]

    if S <: Agents.ContinuousSpace
        cursor_pos = Tuple(plot[:pos][][idx])
    elseif S <: Agents.GridSpace
        cursor_pos = Tuple(Int.(plot[:pos][][idx]))
    end
    a._display_text[] = agent2string(plot.model[], cursor_pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* sizes .- Vec2f0(5), Vec2f0(sizes) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

# TODO: Fix this tooltip
function show_data_poly(inspector::DataInspector, 
            plot::ABMPlot{<:Tuple{<:Agents.ABM{<:S}}},
            idx, ::Makie.Poly) where {S<:GridOrContinuous}
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f0, plot[:pos][][idx], 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    sizes = plot.sizes[]

    if S <: Agents.ContinuousSpace
        cursor_pos = Tuple(plot[:pos][][idx])
    elseif S <: Agents.GridSpace
        cursor_pos = Tuple(Int.(plot[:pos][][idx]))
    end
    a._display_text[] = agent2string(plot.model[], cursor_pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* sizes .- Vec2f0(5), Vec2f0(sizes) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

# 3D space
function Makie.show_data(inspector::DataInspector, 
    plot::ABMPlot{<:Tuple{<:Agents.ABM{<:GridOrContinuous}}}, idx, source::MeshScatter)
    return show_data_3D(inspector, plot, idx, source)
end

function show_data_3D(inspector::DataInspector, 
            plot::ABMPlot{<:Tuple{<:Agents.ABM{<:S}}},
            idx, ::MeshScatter) where {S<:GridOrContinuous}
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f0, plot[:pos][][idx], 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    sizes = plot.sizes[]

    if S <: Agents.ContinuousSpace
        cursor_pos = Tuple(plot[:pos][][idx])
    elseif S <: Agents.GridSpace
        cursor_pos = Tuple(Int.(plot[:pos][][idx]))
    end
    a._display_text[] = agent2string(plot.model[], cursor_pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* sizes .- Vec2f0(5), Vec2f0(sizes) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

##########################################################################################
# Agent to string conversion
##########################################################################################

function agent2string(model::Agents.ABM, 
            cursor_pos::Union{NTuple{2, Int}, NTuple{3, Int}})
    ids = Agents.ids_in_position(cursor_pos, model)
    s = ""
    
    for id in ids
        s *= agent2string(model[id]) * "\n"
    end

    return s
end

function agent2string(model::Agents.ABM, 
            cursor_pos::Union{NTuple{2, Float32}, NTuple{3, Float32}})
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
    if typeof(agent_pos) <: Union{NTuple{2, Float64}, NTuple{3, Float64}}
        agent_pos = round.(agent_pos, digits=2)
    end
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
