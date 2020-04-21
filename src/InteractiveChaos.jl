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
using AbstractPlotting: px
randomcolor(args...) = RGBAf0(rand(Float32), rand(Float32), rand(Float32), 0.75)

include("numericdata/plot_dataset.jl")
include("numericdata/trajectory_highlighter.jl")
include("chaos/orbitdiagram.jl")
include("chaos/poincareclick.jl")
include("billiards/defs_plotting.jl")
include("billiards/defs_animating.jl")
include("billiards/interactive_billiard.jl")

end
