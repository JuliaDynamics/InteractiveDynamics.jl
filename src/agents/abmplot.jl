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
