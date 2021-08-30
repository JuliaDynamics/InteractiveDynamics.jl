using DataStructures

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

mutable struct ParticleStepper{T<:Real, P<:AbstractParticle}
    allparobs::Vector{ParticleObservable{T, P}} # contains tail plot
    balls::Observable{Vector{Point2f0}}
    vels::Observable{Vector{Point2f0}}
    visible::Observable{Bool}
end


function ParticleObservable(p::P, bd, n, ξsin = Point2f0(0, 0)) where {P<:AbstractParticle}
    T = eltype(p.pos)
    i, tmin, cp = DynamicalBilliards.next_collision(p, bd)
    cb = CircularBuffer{Point2f0}(n)
    for i in 1:n; push!(cb, Point2f0(p.pos)); end
    ParticleObservable{T,P}(p, i, tmin, 0, 0, 0, Observable(cb), Observable(ξsin))
end
const ParObs = ParticleObservable

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
    if ξsin ≠ nothing
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
    if intervals ≠ nothing
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
