export subscript, superscript, randomcolor

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

"""
    superscript(i::Int)
Transform `i` to a string that has `i` as a superscript.
"""
function superscript(i::Int)
    if i < 0
        "⁻"*superscript(-i)
    elseif i == 1
        "¹"
    elseif i == 2
        "²"
    elseif i == 3
        "³"
    elseif i == 4
        "⁴"
    elseif i == 5
        "⁵"
    elseif i == 6
        "⁶"
    elseif i == 7
        "⁷"
    elseif i == 8
        "⁸"
    elseif i == 9
        "⁹"
    elseif i == 0
        "⁰"
    else
        join(superscript.(digits(i)))
    end
end

"""
    randomcolor(args...) = RGBAf0(0.9 .* (rand(), rand(), rand())..., 0.75)
"""
randomcolor(args...) = RGBAf0(0.9 .* (rand(), rand(), rand())..., 0.75)

function colors_from_map(cmap, α, N)
    N == 1 && return [AbstractPlotting.to_colormap(cmap, 2)[1]]
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
