export JULIADYNAMICS_COLORS, JULIADYNAMICS_CMAP, JULIADYNAMICS_CMAP_DIVERGING
export lighten_color, darken_color, randomcolor

# const MARKER = Circle(Point2f(0, 0), Float32(1)) # allows pixel size (zoom independent)
const MARKER = :circle
const DEFAULT_BG = RGBf(0.99, 0.99, 0.99)
using Makie: px

JULIADYNAMICS_BLACK = "#1B1B1B"
COLORSCHEME = [
    "#6D44D0",
    "#2CB3BF",
    JULIADYNAMICS_BLACK,
    "#DA5210",
    "#866373",
    "#03502A",
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
    # darken_color(JULIADYNAMICS_COLORS[1], x)
    # for x in range(3.0; step = -0.2, length = 15)


    # darken_color(JULIADYNAMICS_COLORS[1], 2.0),
    # JULIADYNAMICS_COLORS[1],
    # lighten_color(JULIADYNAMICS_COLORS[1], 1.5),

    # (lighten_color(JULIADYNAMICS_COLORS[1], 2.5) +
    #  lighten_color(JULIADYNAMICS_COLORS[2], 3)
    # )/2,
# ]
JULIADYNAMICS_CMAP = reverse(cgrad(:dense)[20:end])

# JULIADYNAMICS_CMAP_DIVERGING = [
#     lighten_color(JULIADYNAMICS_COLORS[1], 2.2),
#     lighten_color(JULIADYNAMICS_COLORS[1], 1.0),
#     darken_color(JULIADYNAMICS_COLORS[3], 2.0),
#     lighten_color(JULIADYNAMICS_COLORS[2] , 1.0),
#     lighten_color(JULIADYNAMICS_COLORS[2], 2.0),
# ]
JULIADYNAMICS_CMAP_DIVERGING = :curl
