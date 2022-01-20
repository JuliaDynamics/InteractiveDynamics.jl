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
        scatterkwargs = NamedTuple(),
    )
end

# ContinuousSpace and GridSpace
function Makie.plot!(abmplot::ABMPlot{<:Tuple{<:Agents.ABM{<:SUPPORTED_AGENTS_SPACES}}})
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
