export JULIADYNAMICS_COLORS, JULIADYNAMICS_CMAP, JULIADYNAMICS_CMAP_DIVERGING
export lighten_color, darken_color, randomcolor

const MARKER = Circle(Point2f(0, 0), Float32(1)) # allows pixel size (zoom independent)
const DEFAULT_BG = RGBf(1.0, 1.0, 1.0)
using Makie: px

COLORSCHEME = [
    "#6F4AC7",
    "#2DB9C5",
    "#1B1B1B",
    "#E82727",
    "#004E41",
]
JULIADYNAMICS_COLORS = to_color.(COLORSCHEME)


"""
    darken_color(c, f = 1.2)
Darken given color `c` by a factor `f`.
If `f` is less than 1, the color is lightened instead.
"""
function darken_color(c, f = 1.2)
    c = to_color(c)
    return RGBAf(clamp.((c.r/f, c.g/f, c.b/f, c.alpha), 0, 1)...)
end

"""
    lighten_color(c, f = 1.2)
Lighten given color `c` by a factor `f`.
If `f` is less than 1, the color is darkened instead.
"""
function lighten_color(c, f = 1.2)
    c = to_color(c)
    return RGBAf(clamp.((c.r*f, c.g*f, c.b*f, c.alpha), 0, 1)...)
end

# JULIADYNAMICS_CMAP = [
#     lighten_color(JULIADYNAMICS_COLORS[3], 1.1),
#     darken_color(JULIADYNAMICS_COLORS[1], 1.2),
#     lighten_color(JULIADYNAMICS_COLORS[1], 1.2),
#     lighten_color(JULIADYNAMICS_COLORS[2], 1.0),
#     lighten_color(JULIADYNAMICS_COLORS[6], 3.5),
# ]
JULIADYNAMICS_CMAP = Reverse(:dense)

# JULIADYNAMICS_CMAP_DIVERGING = [
#     lighten_color(JULIADYNAMICS_COLORS[1], 2.2),
#     lighten_color(JULIADYNAMICS_COLORS[1], 1.0),
#     darken_color(JULIADYNAMICS_COLORS[3], 2.0),
#     lighten_color(JULIADYNAMICS_COLORS[2], 1.0),
#     lighten_color(JULIADYNAMICS_COLORS[2], 2.0),
# ]
JULIADYNAMICS_CMAP_DIVERGING = :curl
