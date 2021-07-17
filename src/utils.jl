export subscript, superscript, randomcolor
export lighten_color, darken_color
export record_interaction

# Color scheme
const MARKER = Circle(Point2f0(0, 0), Float32(1)) # allows pixel size (zoom independent)
const DEFAULT_BG = RGBf0(1.0, 1.0, 1.0)
using Makie: px

# JULIADYNAMICS_COLORS = to_color.(("#7a60bb", "#202020", "#1ba5aa"))
COLORSCHEME = [
    "#6F4AC7",
    "#33CBD8",
    "#000000",
    "#E22411",
    "#968A8A",
    "#B6D840",
]
JULIADYNAMICS_COLORS = to_color.(COLORSCHEME)
export JULIADYNAMICS_COLORS, JULIADYNAMICS_CMAP


"""
    record_interaction(file, figure; framerate = 30, total_time = 10)
Start recording whatever interaction is happening on some `figure` into a video
output in `file` (recommended to end in `".mp4"`).

## Keywords
* `framerate = 30`
* `total_time = 10`: Time to record for, in seconds
# `sleep_time = 1`: Time to call `sleep()` before starting to save.
"""
function record_interaction(file, figure; 
        framerate = 30, total_time = 10, sleep_time = 1,
    )
    ispath(dirname(file)) || mkpath(dirname(file))
    sleep(sleep_time)
    framen = framerate*total_time
    record(figure, file; framerate) do io
        for i = 1:framen
            sleep(1/framerate)
            recordframe!(io)
        end
    end
    return
end
record_interaction(figure::Figure, file; kwargs...) = 
record_interaction(file, figure; kwargs...)


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

JULIADYNAMICS_CMAP = [
    darken_color(JULIADYNAMICS_COLORS[1], 1.1),
    darken_color(JULIADYNAMICS_COLORS[2], 1.2),
    lighten_color(JULIADYNAMICS_COLORS[2], 1.2),
    lighten_color(JULIADYNAMICS_COLORS[3], 1.3),
]

struct CyclicContainer{C} <: AbstractVector{C}
    c::Vector{C}
    n::Int
end
CyclicContainer(c) = CyclicContainer(c, 0)
Base.length(c::CyclicContainer) = length(c.c)
Base.size(c::CyclicContainer) = size(c.c)
Base.getindex(c::CyclicContainer, i) = c.c[mod1(i, length(c.c))]
function Base.getindex(c::CyclicContainer)
    c.n += 1
    c[c.n]
end
Base.iterate(c::CyclicContainer, i = 1) = iterate(c.c, i)

CYCLIC_COLORS = CyclicContainer(JULIADYNAMICS_COLORS)

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
