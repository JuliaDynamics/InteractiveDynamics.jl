export subscript, superscript, randomcolor
export lighten_color, darken_color
export record_interaction

"""
    record_interaction(figure, file; framerate = 30, total_time = 10)
Start recording whatever interaction is happening on some `figure` into a video
output in `file` (recommended to end in `".mp4"`).
Provide also a framerate and a `total_time` to record for (in seconds).
"""
function record_interaction(figure, file; framerate = 30, total_time = 10)
    framen = framerate*total_time
    record(figure, file; framerate) do io
        for i = 1:framen
            sleep(1/framerate)
            recordframe!(io)
        end
    end
    return
end

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
    N == 1 && return [Makie.to_colormap(cmap, 2)[1]]
    cs = [RGBAf0(c.r, c.g, c.b, α) for c in Makie.to_colormap(cmap, N)]
end

function pushupdate!(o::Observable, v)
    push!(o[], v)
    o[] = o[]
    return o
end

"""
    darken_color(c, f = 1.2)
Darken given color `c` by a factor `f`.
If `f` is less than 1, the color is lightened instead.
"""
function darken_color(c, f = 1.2)
    c = to_color(c)
    return RGBAf0(clamp.((c.r/f, c.g/f, c.b/f, c.alpha), 0, 1)...)
end

"""
    lighten_color(c, f = 1.2)
Lighten given color `c` by a factor `f`.
If `f` is less than 1, the color is darkened instead.
"""
function lighten_color(c, f = 1.2)
    c = to_color(c)
    return RGBAf0(clamp.((c.r*f, c.g*f, c.b*f, c.alpha), 0, 1)...)
end

"""
    to_alpha(c, α = 0.75)
Create a color same as `c` but with given alpha channel.
"""
function to_alpha(c, α = 1.2)
    c = to_color(c)
    return RGBAf0(c.r, c.g, c.b, α)
end

##########################################################################################
# Polygon stuff
##########################################################################################
using Makie.GeometryBasics # for using Polygons
export rotate2D, scale, Polygon, Point2f0

translate(p::Polygon, point) = Polygon(decompose(Point2f0, p.exterior) .+ point)

"""
    rotate2D(p::Polygon, θ)
Rotate given polygon counter-clockwise by `θ` (in radians).
"""
function rotate2D(p::Polygon, θ)
    sinφ, cosφ = sincos(θ)
    Polygon(map(
        p -> Point2f0(cosφ*p[1] - sinφ*p[2], sinφ*p[1] + cosφ*p[2]),
        decompose(Point2f0, p.exterior)
    ))
end

"""
    scale(p::Polygon, s)
Scale given polygon by `s`, assuming polygon's "center" is the origin.
"""
scale(p::Polygon, s) = Polygon(decompose(Point2f0, p.exterior) .* Float32(s))
