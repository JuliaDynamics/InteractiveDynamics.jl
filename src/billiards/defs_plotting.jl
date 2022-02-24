# DynamicalBilliards.jl constants
SVector = DynamicalBilliards.SVector
Obstacle = DynamicalBilliards.Obstacle
Billiard = DynamicalBilliards.Billiard
AbstractParticle = DynamicalBilliards.AbstractParticle
using Makie: RGBf, RGBAf

obcolor(::Obstacle) = RGBf(0,0.6,0)
obcolor(::Union{DynamicalBilliards.RandomWall, DynamicalBilliards.RandomDisk}) = RGBf(149/255, 88/255, 178/255)
obcolor(::Union{DynamicalBilliards.SplitterWall, DynamicalBilliards.Antidot, DynamicalBilliards.Ellipse}) = RGBf(0.8,0.0,0)
obcolor(::DynamicalBilliards.PeriodicWall) = RGBf(0.8,0.8,0)
obfill(o::DynamicalBilliards.Obstacle) = RGBAf(obcolor(o).r, obcolor(o).g, obcolor(o).b, 0.5)
obfill(o::Union{DynamicalBilliards.Antidot, DynamicalBilliards.Ellipse}) = RGBAf(obcolor(o), 0.1)
obls(::Obstacle) = nothing
obls(::Union{DynamicalBilliards.SplitterWall, DynamicalBilliards.Antidot, DynamicalBilliards.Ellipse}) = :dash
obls(::DynamicalBilliards.PeriodicWall) = :dotted
oblw(::Obstacle) = 2.0

function bdplot(args...; kwargs...)
    fig = Figure()
    ax = Axis(fig[1,1]; aspect = DataAspect())
    bdplot!(ax, args...; kwargs...)
    return fig, ax
end

function bdplot!(ax, o::T; kwargs...) where {T}
    error("Element of type $T does not have a plotting definition yet.")
end

function bdplot!(ax, o::DynamicalBilliards.Semicircle; kwargs...)
    θ1 = atan(o.facedir[2], o.facedir[1]) + π/2 # start of semicircle
    θ2 = θ1 + π
    θ = range(θ1, θ2; length = 200)
    p = [Point2f(cos(t)*o.r + o.c[1], sin(t)*o.r + o.c[2]) for t in θ]
    lines!(ax, p; color = obcolor(o), linewidth = oblw(o), linestyle = obls(o),
    kwargs...)
end

function bdplot!(ax, w::DynamicalBilliards.Wall; kwargs...)
    lines!(ax, Float32[w.sp[1],w.ep[1]], Float32[w.sp[2],w.ep[2]];
    color = obcolor(w), linewidth = oblw(w), kwargs...)
end

function bdplot!(ax, o::DynamicalBilliards.Circular; kwargs...)
    θ = range(0, 2π; length = 700)
    p = [Point2f(cos(t)*o.r + o.c[1], sin(t)*o.r + o.c[2]) for t in θ]
    poly!(ax, p; color = obfill(o), kwargs...)
    lines!(ax, p; color = obcolor(o), linewidth = oblw(o), linestyle = obls(o),
    kwargs...)
end

function bdplot!(ax, bd::Billiard; kwargs...)
    xmin, ymin, xmax, ymax = DynamicalBilliards.cellsize(bd)
    dx = xmax - xmin; dy = ymax - ymin
    for obst in bd; bdplot!(ax, obst; kwargs...); end
    if !isinf(xmin) && !isinf(xmax)
        Makie.xlims!(ax, xmin - 0.01dx, xmax + 0.01dx)
    end
    if !isinf(ymin) && !isinf(ymax)
        Makie.ylims!(ax, ymin - 0.01dy, ymax + 0.01dy)
    end
    remove_axis!(ax)
    ax.aspect = DataAspect()
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

function _estimate_vr(bd)
    xmin, ymin, xmax, ymax = DynamicalBilliards.cellsize(bd)
    f = max((xmax-xmin), (ymax-ymin))
    isinf(f) && error("cellsize of billiard is infinite")
    vr = Float32(f/25)
end

function bdplot!(ax, bd, ps::Vector{<:AbstractParticle};
    use_cell = true, kwargs...)
    c = haskey(kwargs, :color) ? kwargs[:color] : Makie.RGBf(0,0,0)
    N = length(ps)
    xs, ys = Observable(zeros(Float32, N)), Observable(zeros(Float32, N))
    vxs, vys = Observable(zeros(Float32, N)), Observable(zeros(Float32, N))

    # need heuristic for ms and vr
    ms = 6
    vr = _estimate_vr(bd)
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
    marker = Circle(Point2f(xs[][1], ys[][1]), Float32(1))

    scatter!(ax, xs, ys; color = c, marker = marker, markersize = ms*px, strokewidth = 0.0)
    arrows!(ax, xs, ys, vxs, vys;
        normalize = false, arrowsize = 0.01px,
        linewidth  = 2,
    )
    return xs, ys
end


function obstacle_axis!(figlocation, intervals)
    bmapax = Axis(figlocation)
    bmapax.xlabel = "arclength, ξ"
    bmapax.ylabel = "sine of normal angle, sin(θ)"
    bmapax.targetlimits[] = BBox(intervals[1], intervals[end], -1, 1)

    ticklabels = ["$(round(ξ, sigdigits=4))" for ξ in intervals[2:end-1]]
    bmapax.xticks = (Float32[intervals[2:end-1]...], ticklabels)
    for (i, ξ) in enumerate(intervals[2:end-1])
        lines!(bmapax, [Point2f(ξ, -1), Point2f(ξ, 1)]; linestyle = :dash, color = :black)
    end
    obstacle_ticklabels = String[]
    obstacle_ticks = Float32[]
    for (i, ξ) in enumerate(intervals[1:end-1])
        push!(obstacle_ticks, ξ + (intervals[i+1] - ξ)/2)
        push!(obstacle_ticklabels, string(i))
    end
    ylims!(bmapax, -1, 1)
    xlims!(bmapax, 0, intervals[end])

    obax = Axis(figlocation)
    MakieLayout.deactivate_interaction!(obax, :rectanglezoom)
    obax.xticks = (obstacle_ticks, obstacle_ticklabels)
    obax.xaxisposition = :top
    obax.xticklabelalign = (:center, :bottom)
    obax.xlabel = "obstacle index"
    obax.xgridvisible = false
    hideydecorations!(obax)
    hidespines!(obax)
    xlims!(obax, 0, intervals[end])
    return bmapax
end
