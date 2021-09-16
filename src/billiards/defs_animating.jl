using DataStructures

######################################################################################
# Observable for single particle, which auto-steps its plotted tail/boundary map
######################################################################################

mutable struct ParticleObservable{T<:Real, P<:AbstractParticle}
    # Fields necessary for simulation
    p::P         # particle
    i::Int       # index of obstacle to be collided with
    tmin::T      # time to next collision
    t::T         # current time (resets at each collision)
    n::Int       # number of collisions done so far
    T::T         # total time
    # Fields used in plotting
    tail::Observable{CircularBuffer{Point2f0}}
    ξsin::Observable{Point2f0}   # Only used when plotting in boundary map
end
const ParObs = ParticleObservable

function ParticleObservable(p::P, bd, n, ξsin = Point2f0(0, 0)) where {P<:AbstractParticle}
    T = eltype(p.pos)
    i, tmin, cp = DynamicalBilliards.next_collision(p, bd)
    cb = CircularBuffer{Point2f0}(n)
    fill!(cb, Point2f0(p.pos))
    ParticleObservable{T,P}(p, i, tmin, 0, 0, 0, Observable(cb), Observable(ξsin))
end

function rebind_partobs!(p::ParticleObservable, p0::AbstractParticle, bd, ξsin = p.ξsin[])
    i, tmin, cp = DynamicalBilliards.next_collision(p0, bd)
    ξ = sφ = 0f0 # TODO: Use boundary map on cp
    p.p.pos = p0.pos
    p.p.vel = p0.vel
    DynamicalBilliards.ismagnetic(p.p) && (p.p.center = DynamicalBilliards.find_cyclotron(p.p))
    p.i, p.tmin, p.t, p.n, p.T = i, tmin, 0, 0, 0
    L = length(p.tail[])
    append!(p.tail[], [Point2f0(p0.pos) for i in 1:L])
    p.tail[] = p.tail[]
    if ξsin !== nothing
        p.ξsin[] = ξsin # This can only be updated from bmap, which gives selection directly
    end
end

function animstep!(parobs, bd, dt, updateplot = true, intervals = nothing)
    if parobs.t + dt - parobs.tmin > 0
        rt = parobs.tmin - parobs.t # remaining time
        animbounce!(parobs, bd, rt, updateplot, intervals)
    else
        DynamicalBilliards.propagate!(parobs.p, dt)
        parobs.t += dt
        push!(parobs.tail[], parobs.p.pos)
        if updateplot
            parobs.tail[] = parobs.tail[] # trigger update
        end
    end
    return
end

function animbounce!(parobs, bd, rt, updateplot = true, intervals = nothing)
    DynamicalBilliards.propagate!(parobs.p, rt)
    DynamicalBilliards._correct_pos!(parobs.p, bd[parobs.i])
    DynamicalBilliards.resolvecollision!(parobs.p, bd[parobs.i])
    DynamicalBilliards.ismagnetic(parobs.p) && (parobs.p.center = DynamicalBilliards.find_cyclotron(parobs.p))
    # `intervals` are the boundary map intervals (needs knowledge of DynamicalBilliards.jl)
    if intervals !== nothing
        ξ, sφ = DynamicalBilliards.to_bcoords(parobs.p.pos, parobs.p.vel, bd[parobs.i])
        ξ += intervals[parobs.i]
        parobs.ξsin[] = (ξ, sφ)
    end
    i, tmin, = DynamicalBilliards.next_collision(parobs.p, bd)
    parobs.i = i
    parobs.tmin = tmin
    parobs.t = 0
    parobs.T += tmin
    parobs.n += 1
    push!(parobs.tail[], parobs.p.pos)
    if updateplot
        parobs.tail[] = parobs.tail[] # trigger update
    end
    return
end


######################################################################################
# Animation stepper for a group of particles. Includes plotted quiver field
######################################################################################

mutable struct ParticleStepper{T<:Real, P<:AbstractParticle}
    allparobs::Vector{ParticleObservable{T, P}} # contains tail plot
    balls::Observable{Vector{Point2f0}}
    vels::Observable{Vector{Point2f0}}
end


function bdplot_initialize_stepper!(ax, ps::Vector{<:AbstractParticle}, bd;
    # Internal keyword arguments (e.g. a second axis for boundary map plot)
    
    # Remaining arguments for tuning plotting, e.g. color, linewidths, etc.
    kwargs...  # keywords from `interactive_billiard`
    )

    N = length(ps)
    allparobs = [ParObs(p, bd, tail) for p in ps]

    cs = if !(colors isa Vector) || length(colors) ≠ N
        colors_from_map(colors, α, N)
    else
        to_color.(colors)
    end


    # Plot tails
    for (i, p) in enumerate(allparobs)
        x = to_color(cs[i])
        if fade
            x = [RGBAf0(x.r, x.g, x.b, i/tail) for i in 1:tail]
        end
        lines!(ax, p.tail; color = x, linewidth = tailwidth)
    end
    
    balls = Observable([Point2f0(p.p.pos) for p in allparobs])
    vels = Observable([particle_size * vr * Point2f0(p.p.vel) for p in allparobs])

    if plot_particles # plot ball and arrow as a particle
        # TODO: Allow adjusting width etc of quiver markers with individual multiplier
        particle_plots = (
            scatter!(
                ax, balls; color = darken_color.(cs),
                marker = MARKER, markersize = 8*particle_size*Makie.px,
                strokewidth = 0.0,
            ),
            arrows!(
                ax, balls, vels; arrowcolor = darken_color.(cs),
                linecolor = darken_color.(cs),
                normalize = false, arrowsize = particle_size*vr/3,
                linewidth  = particle_size*4,
            )
        )
    end

    # TODO: actually make struct



end


# TODO: Animation stepping function.

# TODO: Rebind stepper function.