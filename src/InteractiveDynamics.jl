module InteractiveDynamics

using Makie
using Observables
using OSMMakie
using GraphMakie

include("colors.jl")
include("utils.jl")
using Requires

warnstring(pkg) = @warn """
$(pkg) moved to Julia 1.9 and now uses package extrensions to provide visualizations.
"InteractiveDynamics.jl is obsolete. Remove it from your project if you use Juila 1.9+
"""

function __init__()
    @require DynamicalSystems = "61744808-ddfa-5f27-97ff-6e42cc95d634" begin
        warnstring("DynamicalSystems.jl")
    end
    @require DynamicalBilliards = "4986ee89-4ee5-5cef-b6b8-e49ba721d7a5" begin
        include("billiards/defs_plotting.jl")
        include("billiards/defs_animating.jl")
        include("billiards/premade_anim_functions.jl")
        include("billiards/exports.jl")
    end
    @require Agents = "46ada45e-f475-11e8-01d0-f70cc89e6671" begin
        include("agents/abmplot.jl")
        include("agents/lifting.jl")
        include("agents/interaction.jl")
        include("agents/inspection.jl")
        include("agents/convenience.jl")
        include("agents/deprecations.jl")
    end
end

end
