module InteractiveChaos

using AbstractPlotting, Observables, MakieLayout

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
    elseif i ≥ 10
        join(subscript.(digits(i)))
    else
        string(i)
    end
end

const MARKER = Circle(Point2f0(0, 0), Float32(1)) # allows pixel size (zoom independent)
const DEFAULT_BG = RGBf0(0.98, 0.97, 0.99)
using AbstractPlotting: px
randomcolor(args...) = RGBAf0(0.9 .* (rand(), rand(), rand())..., 0.75)


# JULIADYNAMICS_CMAP = to_color.(("#7a60bb", "#624d96", "#202020", "#17888c", "#1fb6bb"))
JULIADYNAMICS_COLORS = to_color.(("#7a60bb", "#202020", "#1ba5aa"))

function colors_from_map(cmap, α, N)
    N == 1 && return [RGBAf0(0, 0, 0, 1)]
    cs = [RGBAf0(c.r, c.g, c.b, α) for c in AbstractPlotting.to_colormap(cmap, N)]
end

function pushupdate!(o::Observable, v)
    push!(o[], v)
    o[] = o[]
    return o
end


include("numericdata/plot_dataset.jl")
include("numericdata/trajectory_highlighter.jl")
include("chaos/orbitdiagram.jl")
include("chaos/poincareclick.jl")
include("billiards/defs_plotting.jl")
include("billiards/defs_animating.jl")
include("billiards/interactive_billiard.jl")

end
