export agent2string

"""
Define ABMPlot plotting function with some attribute defaults.

Order of plot layers:
1. OSMPlot, if `model.space isa OpenStreetMapSpace`
2. static preplot, if `static_preplot! != nothing`
3. heatmap, if `heatarray != nothing`
4. agent positions, depending on type of `model.space`

"""
@recipe(ABMPlot, model) do scene
    Theme(
        # insert InteractiveDynamics theme here?   
    )
    Attributes(
        ac = JULIADYNAMICS_COLORS[1],
        as = 10,
        am = :circle,
        offset = nothing,
        heatarray = nothing,
        heatkwargs = NamedTuple(),
        add_colorbar = true,
        static_preplot! = nothing, 
        scatterkwargs = NamedTuple(),
        add_controls = false,
        add_data_plots = false,
        # Attribute _ax is currently necessary to have a reference to the parent Axis.
        # Makie's recipe system still works on the old system of `Scene`s which have no
        # concept of a parent Axis. Makie devs plan to enable this in the future. Until then
        # we will have to work around it with this little hack.
        _ax = nothing,
        used_poly = false
    )
end

const SUPPORTED_SPACES =  Union{
    Agents.DiscreteSpace,
    Agents.ContinuousSpace,
    Agents.OpenStreetMapSpace,
}

function Makie.plot!(abmplot::ABMPlot{<:Tuple{<:Agents.ABM{<:SUPPORTED_SPACES}}}) 
    pos, color, marker, markersize, heatobs = lift_attributes(abmplot.model, abmplot.ac, 
        abmplot.as, abmplot.am, abmplot.offset, abmplot.heatarray, abmplot.used_poly)
    
    model = abmplot.model[]
    ax = abmplot._ax[]
    if !isnothing(ax)
        plot_agents_space!(ax, model)
    end

    if model.space isa Agents.OpenStreetMapSpace
        osm_plot = Main.OSMMakie.osmplot!(abmplot, model.space.map)
        osm_plot.inspectable[] = false
    end

    if !isnothing(heatobs[])
        merged_heatkwargs = merge((; colormap = JULIADYNAMICS_CMAP), abmplot.heatkwargs)
        hmap = heatmap!(abmplot, heatobs; merged_heatkwargs...)
        if abmplot.add_colorbar[]
            @assert ax !== nothing axis_error
            fig = ax.parent
            Colorbar(fig[1, 1][1, 2], hmap, width = 20)
        end
        # rowsize!(fig[1,1].fig.layout, 1, abmplot.scene.px_area[].widths[2]) # Colorbar height = axis height
    end
    
    if !isnothing(abmplot.static_preplot![])
        static_plot = abmplot.static_preplot!(abmplot, model)
        static_plot.inspectable[] = false
    end
    
    T = typeof(pos[])
    if T<:Vector{Point2f0} # 2d space
        if typeof(marker[])<:Vector{<:Polygon{2}}
            poly_plot = poly!(abmplot, marker; color, abmplot.scatterkwargs...)
            poly_plot.inspectable[] = false # disable inspection for poly until fixed
        else
            scatter!(abmplot, pos; color, marker, markersize, abmplot.scatterkwargs...)
        end
    elseif T<:Vector{Point3f0} # 3d space
        marker[] == :circle && (marker = Sphere(Point3f0(0), 1))
        meshscatter!(abmplot, pos; color, marker, markersize, abmplot.scatterkwargs...)
    else
        error("""
            Cannot resolve agent positions: $(T)
            Please verify the correctness of the `pos` field of your agent struct.
            """)
    end
    
    if abmplot.add_controls[]
        @assert ax !== nothing axis_error
        # add controls to axis
    end

    if abmplot.add_data_plots[]
        @assert ax !== nothing axis_error
        # add data exploration plots to right side of figure = ax.parent
    end

    return abmplot
end

"Plot space and/or set axis limits."
function plot_agents_space!(ax, model)
    if model.space isa Agents.OpenStreetMapSpace
        return
    elseif model.space isa Agents.ContinuousSpace
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

function default_static_preplot(ax, model)
    return nothing
end

axis_error = """\n
Requires an Axis to which an element will be added.
Please first explicitly construct a Figure and Axis to plot into, then provide `_ax::Axis` as a keyword argument to your in-place function call.

Example:
    fig = Figure()
    ax = Axis(fig[1,1][1,1])
    p = abmplot!(model; _ax = ax)
"""