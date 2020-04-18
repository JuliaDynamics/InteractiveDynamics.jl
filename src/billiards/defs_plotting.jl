# Colors of JuliaDynamics
MAIN = "#624d96"  # main color of the org theme
ACCENT = "#17888c"
WHITE = "fff"
BLACK = "#202020"

# Colors of 3b1b
BLUE = "#1C758A"
BROWN = "#736357"

# DynamicalBilliards.jl constants
using DynamicalBilliards, AbstractPlotting, Observables
using DynamicalBilliards: SV
using AbstractPlotting: RGBf0, RGBAf0

obcolor(::Obstacle) = RGBf0(0,0.6,0)
obcolor(::Union{RandomWall, RandomDisk}) = RGBf0(149/255, 88/255, 178/255)
obcolor(::Union{SplitterWall, Antidot, Ellipse}) = RGBf0(0.8,0.0,0)
obcolor(::PeriodicWall) = RGBf0(0.8,0.8,0)
obfill(o::Obstacle) = RGBAf0(obcolor(o), 0.5)
obfill(o::Union{Antidot, Ellipse}) = RGBAf0(obcolor(o)..., 0.1)
obls(::Obstacle) = "solid"
obls(::Union{SplitterWall, Antidot, Ellipse}) = "dashed"
obls(::PeriodicWall) = "dotted"
oblw(::Obstacle) = 2.0


function bdplot!(ax, s::Semicircle; kwargs...)
    θ1 = atan(s.facedir[2], s.facedir[1]) + π # start of semicircle
    θ2 = θ1 + π
    arc!(ax, Point2f0(s.c...), s.r, θ1, θ2; color = obcolor(s), linewidth = oblw(s),
         scale_plot=false, kwargs...)
end

function bdplot!(ax, w::Wall; kwargs...)
    lines!(ax, Float32[w.sp[1],w.ep[1]], Float32[w.sp[2],w.ep[2]];
    color = obcolor(w), linewidth = oblw(w), scale_plot=false, kwargs...)
end

function bdplot!(ax, o::Circular; kwargs...)
    c = Circle(Point2f0(o.c...), Float32(o.r))
    # scatter!(ax, [o.c[1]], [o.c[2]]; marker = c, color = obfill(o),
    # strokecolor = obcolor(o), strokewidth = oblw(o), scale_plot=false, kwargs...)
    poly!(ax, c; color = obfill(o), scale_plot=false, kwargs...)
    lines!(ax, c; color = obcolor(o), linewidth = oblw(o), scale_plot=false, kwargs...)
end

function bdplot!(ax, bd::Billiard; kwargs...)
    xmin, ymin, xmax, ymax = DynamicalBilliards.cellsize(bd)
    dx = xmax - xmin; dy = ymax - ymin
    for obst in bd; bdplot!(ax, obst; show_axis = false, kwargs...); end
    if !isinf(xmin) && !isinf(xmax)
        AbstractPlotting.xlims!(ax, xmin - 0.1dx, xmax + 0.1dx)
    end
    if !isinf(ymin) && !isinf(ymax)
        AbstractPlotting.ylims!(ax, ymin - 0.1dy, ymax + 0.1dy)
    end
    remove_axis!(ax)
    return ax
end

function remove_axis!(ax)
    ax.bottomspinevisible = false
    ax.leftspinevisible = false
    ax.topspinevisible = false
    ax.rightspinevisible = false
    ax.xgridvisible = false
    ax.ygridvisible = false
    ax.xticksvisible = false
    ax.yticksvisible = false
    ax.xticklabelsvisible = false
    ax.yticklabelsvisible = false
end

bdplot!(ax, p::AbstractParticle; kwargs...) = bdplot!(ax, [p]; kwargs...)


function bdplot!(ax, ps::Vector{<:AbstractParticle};
    use_cell = true, kwargs...)
    c = haskey(kwargs, :color) ? kwargs[:color] : AbstractPlotting.RGBf0(0,0,0)
    N = length(ps)
    xs, ys = Observable(zeros(Float32, N)), Observable(zeros(Float32, N))
    vxs, vys = Observable(zeros(Float32, N)), Observable(zeros(Float32, N))

    # need heuristic for ms and vr
    ms = 6
    vr = 0.05
    for i in 1:N
        p = ps[i]
        pos = use_cell ? p.pos + p.current_cell : p.pos
        xs[][i] = pos[1]
        ys[][i] = pos[2]
        θ = atan(p.vel[2], p.vel[1])
        vxs[][i] = vr*cos(θ)
        vys[][i] = vr*sin(θ)
    end
    # important: marker hack for zoom-independent size. Will change in the future
    # to allow something like `markerspace = :display`
    marker = Circle(Point2f0(xs[][1], ys[][1]), Float32(1))

    scatter!(ax, xs, ys; color = c, marker = marker, markersize = ms*px)
    arrows!(ax, xs, ys, vxs, vys;
        normalize = false, arrowsize = 0.01px,
        linewidth  = 2,
    )
    return xs, ys
end
