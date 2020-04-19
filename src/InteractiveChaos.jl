module InteractiveChaos

using AbstractPlotting, Observables

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

include("numericdata/plot_dataset.jl")
include("numericdata/trajectory_highlighter.jl")
include("chaos/orbitdiagram.jl")
include("chaos/poincareclick.jl")
include("billiards/defs_plotting.jl")
include("billiards/defs_animating.jl")
include("billiards/interactive_billiard.jl")

end
