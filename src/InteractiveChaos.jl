module InteractiveChaos

using AbstractPlotting, Observables
using AbstractPlotting.MakieLayout

"""
    subscript(i::Int)
Transform `i` to a string that has `i` as a subscript.
"""
function subscript(i::Int)
    if i < 0
        "₋"*subscript(-i)
    elseif i == 1
        "₁"
    elseif i == 2
        "₂"
    elseif i == 3
        "₃"
    elseif i == 4
        "₄"
    elseif i == 5
        "₅"
    elseif i == 6
        "₆"
    elseif i == 7
        "₇"
    elseif i == 8
        "₈"
    elseif i == 9
        "₉"
    elseif i == 0
        "₀"
    else
        join(subscript.(digits(i)))
    end
end

const MARKER = Circle(Point2f0(0, 0), Float32(1)) # allows pixel size (zoom independent)
const DEFAULT_BG = RGBf0(0.99, 0.98, 1.0)
using AbstractPlotting: px
randomcolor(args...) = RGBAf0(0.9 .* (rand(), rand(), rand())..., 0.75)


# JULIADYNAMICS_COLORS = to_color.(("#7a60bb", "#202020", "#1ba5aa"))
JULIADYNAMICS_COLORS = to_color.(["#7d53e7", "#202020", "#17c7cd"])

function colors_from_map(cmap, α, N)
    N == 1 && return [RGBAf0(0, 0, 0, 1)]
    cs = [RGBAf0(c.r, c.g, c.b, α) for c in AbstractPlotting.to_colormap(cmap, N)]
end

function pushupdate!(o::Observable, v)
    push!(o[], v)
    o[] = o[]
    return o
end

function darken_color(c, f = 1.2)
    tc = to_color(c)
    return RGBAf0(c.r/f, c.g/f, c.b/f, c.alpha)
end

using Requires
using Observables

function __init__()
    @require DynamicalSystems = "61744808-ddfa-5f27-97ff-6e42cc95d634" begin
        include("numericdata/plot_dataset.jl")
        include("numericdata/trajectory_highlighter.jl")
        include("chaos/orbitdiagram.jl")
        include("chaos/poincareclick.jl")
    end
    @require DynamicalBilliards = "4986ee89-4ee5-5cef-b6b8-e49ba721d7a5" begin
        include("billiards/defs_plotting.jl")
        include("billiards/defs_animating.jl")
        include("billiards/interactive_billiard.jl")
    end
    @require Agents = "46ada45e-f475-11e8-01d0-f70cc89e6671" begin
        include("agents/agents.jl")
    end
end

end
