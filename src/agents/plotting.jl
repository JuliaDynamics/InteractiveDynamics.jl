const SUPPORTED_AGENTS_SPACES =  Union{
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

    abmplot!(ax, model;
        pos = abmstepper.pos, colors = abmstepper.colors, markers = abmstepper.markers,
        sizes = abmstepper.sizes, scatterkwargs...
    )
    return
end

"Plot space and/or set axis limits."
function plot_agents_space!(ax, model)
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

function default_static_preplot(ax, model)
    if model.space isa Agents.OpenStreetMapSpace
        return Main.OSMMakie.osmplot!(ax, model.space.map)
    else
        return nothing
    end
end
