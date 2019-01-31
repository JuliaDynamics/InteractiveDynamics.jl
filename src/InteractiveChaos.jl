module InteractiveChaos

using Reexport
@reexport using DynamicalSystems
using AbstractPlotting, Makie

"""
    subscript(i::Int)
Transform `i` to a string that has `i` as a subscript.
"""
function subscript(i::Int)
    if i == 1
        "₁"
    elseif i == 2
        "₂"
    elseif i == 3
        "₃"
        # TODO: Add until 9
    else
        string(i)
    end
end

include("orbitdiagram.jl")
include("poincareclick.jl")

export interactive_orbitdiagram

end
