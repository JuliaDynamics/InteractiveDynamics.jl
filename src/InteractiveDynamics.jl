module InteractiveDynamics

using Makie, Observables, OSMMakie

include("colors.jl")
include("utils.jl")
using Requires

function __init__()
    @require DynamicalSystems = "61744808-ddfa-5f27-97ff-6e42cc95d634" begin
        # include("numericdata/plot_dataset.jl")
        # include("numericdata/trajectory_highlighter.jl")
        include("chaos/orbitdiagram.jl")
        include("chaos/poincareclick.jl")
        include("chaos/trajanim.jl")
        include("chaos/cobweb.jl")
        include("chaos/brainscan.jl")
    end
    @require DynamicalBilliards = "4986ee89-4ee5-5cef-b6b8-e49ba721d7a5" begin
        include("billiards/defs_plotting.jl")
        include("billiards/defs_animating.jl")
        include("billiards/interactive_billiard.jl")
    end
    @require Agents = "46ada45e-f475-11e8-01d0-f70cc89e6671" begin
        include("agents/abmplot.jl")
        include("agents/lifting.jl")
        include("agents/interaction.jl")
        include("agents/inspection.jl")
        include("agents/convenience.jl")
    end
end

end
