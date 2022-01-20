export agent2string

"Define ABMPlot plotting function with some attribute defaults."
@recipe(ABMPlot, model) do scene
    Theme(
        # insert InteractiveDynamics theme here?   
    )
    Attributes(
        pos = nothing,
        colors = JULIADYNAMICS_COLORS[1],
        markers = :circle,
        sizes = 10,
        heatobs = nothing,
        heatkwargs = NamedTuple(),
        add_colorbar = true,
        static_preplot! = default_static_preplot,
        scatterkwargs = NamedTuple(),
    )
end

const SUPPORTED_SPACES =  Union{
    Agents.DiscreteSpace,
    Agents.ContinuousSpace,
    Agents.OpenStreetMapSpace,
}

function Makie.plot!(abmplot::ABMPlot{<:Tuple{<:Agents.ABM{<:SUPPORTED_SPACES}}})
    plot_agents_space!(abmplot, model)

    if !isnothing(abmplot.heatobs[])
        merged_heatkwargs = merge((colormap=JULIADYNAMICS_CMAP,), abmplot.heatkwargs[])
        hmap = heatmap!(abmplot, abmplot.heatobs[]; merged_heatkwargs...)
        if add_colorbar 
            fig = abmplot.parent
            Colorbar(fig[1, 1][1, 2], hmap, width = 20)
        end
        # rowsize!(fig[1,1].fig.layout, 1, abmplot.scene.px_area[].widths[2]) # Colorbar height = axis height
    end

    static_plot = static_preplot!(abmplot, model)
    !isnothing(static_plot) && (static_plot.inspectable[] = false)
    
    T = typeof(abmplot[:pos][])
    if T<:Vector{Point2f0} # 2d space
        if typeof(abmplot[:markers][])<:Vector{<:Polygon{2}}
            poly!(abmplot, abmplot[:markers];
                color=abmplot[:colors], abmplot[:scatterkwargs]...
            )
        else
            scatter!(abmplot, abmplot[:pos];
                color = abmplot[:colors], marker = abmplot[:markers], 
                markersize = abmplot[:sizes], abmplot[:scatterkwargs]...
            )
        end
    elseif T<:Vector{Point3f0} # 3d space
        abmplot.markers[] == :circle && (abmplot.markers = Sphere(Point3f0(0), 1))
    
        meshscatter!(abmplot, abmplot[:pos];
            color = abmplot[:colors], marker = abmplot[:markers], 
            markersize = abmplot[:sizes], abmplot[:scatterkwargs]...
        )
    else
        error("""
            Cannot resolve agent positions: $(T)
            Please verify the correctness of the `pos` field of your agent struct.
            """)
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
    if model.space isa Agents.OpenStreetMapSpace
        return Main.OSMMakie.osmplot!(ax, model.space.map)
    else
        return nothing
    end
end
