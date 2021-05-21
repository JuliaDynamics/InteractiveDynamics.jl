module InteractiveDynamics

using Makie, Observables
using Makie.MakieLayout

const MARKER = Circle(Point2f0(0, 0), Float32(1)) # allows pixel size (zoom independent)
const DEFAULT_BG = RGBf0(1.0, 1.0, 1.0)
using Makie: px

# JULIADYNAMICS_COLORS = to_color.(("#7a60bb", "#202020", "#1ba5aa"))
JULIADYNAMICS_COLORS = to_color.(["#7d53e7", "#202020", "#17c7cd"])
JULIADYNAMICS_CMAP = to_color.(["#2c1633", "#744cd7", "#00ffc1"])
export JULIADYNAMICS_COLORS

include("utils.jl")
using Requires
using Observables

Label = Makie.Label

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
        include("agents/stepping.jl")
        include("agents/plots_videos.jl")
        include("agents/interactive_parameters.jl")
    end
end

end
