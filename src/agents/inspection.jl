##########################################################################################
# Agent inspection on mouse hover
#
# Note: This only works in combination with ABMPlot.
##########################################################################################

# 2D space
function Makie.show_data(inspector::DataInspector,
            plot::_ABMPlot{<:Tuple{<:Agents.ABM{<:SUPPORTED_SPACES}}},
            idx, source::Scatter)
    if plot._used_poly[]
        return show_data_poly(inspector, plot, idx, source)
    else
        return show_data_2D(inspector, plot, idx, source)
    end
end

function show_data_2D(inspector::DataInspector,
            plot::_ABMPlot{<:Tuple{<:Agents.ABM{<:S}}},
            idx, source::Scatter) where {S<:SUPPORTED_SPACES}
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    pos = source.converted[1][][idx]
    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f, pos, 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    size = source.markersize[] isa Vector ? source.markersize[][idx] : source.markersize[]

    model = plot.abmobs[].model[]
    id = collect(Agents.allids(model))[idx]
    a._display_text[] = agent2string(model, model[id].pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* size .- Vec2f0(5), Vec2f0(size) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

# TODO: Fix this tooltip
function show_data_poly(inspector::DataInspector,
            plot::_ABMPlot{<:Tuple{<:Agents.ABM{<:S}}},
            idx, ::Makie.Poly) where {S<:SUPPORTED_SPACES}
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f, plot[:pos][][idx], 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    sizes = plot.sizes[]

    if S <: Agents.ContinuousSpace
        agent_pos = Tuple(plot[:pos][][idx])
    elseif S <: Agents.GridSpace
        agent_pos = Tuple(Int.(plot[:pos][][idx]))
    end
    a._display_text[] = agent2string(plot.abmobs[].model[], agent_pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* sizes .- Vec2f0(5), Vec2f0(sizes) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

# 3D space
function Makie.show_data(inspector::DataInspector,
            plot::_ABMPlot{<:Tuple{<:Agents.ABM{<:SUPPORTED_SPACES}}},
            idx, source::MeshScatter)
    # need to dispatch here should we for example have 3D polys at some point
    return show_data_3D(inspector, plot, idx, source)
end

function show_data_3D(inspector::DataInspector,
            plot::_ABMPlot{<:Tuple{<:Agents.ABM{<:S}}},
            idx, source::MeshScatter) where {S<:SUPPORTED_SPACES}
    a = inspector.plot.attributes
    scene = Makie.parent_scene(plot)

    pos = source.converted[1][][idx]
    proj_pos = Makie.shift_project(scene, plot, to_ndim(Point3f, pos, 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)
    size = source.markersize[] isa Vector ? source.markersize[][idx] : source.markersize[]

    model = plot.abmobs[].model[]
    id = collect(Agents.allids(model))[idx]
    a._display_text[] = agent2string(model, model[id].pos)
    a._bbox2D[] = FRect2D(proj_pos .- 0.5 .* size .- Vec2f0(5), Vec2f0(size) .+ Vec2f0(10))
    a._px_bbox_visible[] = true
    a._bbox_visible[] = false
    a._visible[] = true

    return true
end

##########################################################################################
# Agent to string conversion
##########################################################################################

function agent2string(model::Agents.ABM{<:S}, agent_pos) where {S<:SUPPORTED_SPACES}
    if S<:Agents.GridSpace
        ids = Agents.ids_in_position(agent_pos, model)
    elseif S<:Agents.ContinuousSpace
        ids = Agents.nearby_ids(agent_pos, model, 0.0)
    elseif S<:Agents.OpenStreetMapSpace
        ids = Agents.nearby_ids(agent_pos, model, 0.0)
    else
        ids = []
    end
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
    if agent_pos isa Tuple && agent_pos isa NTuple{length(agent_pos), AbstractFloat}
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
        elseif V <: Tuple && V <: NTuple{length(val), AbstractFloat}
            val = round.(val, digits=2)
        end
        agentstring *= "$(field): $val\n"
    end

    return agentstring
end
