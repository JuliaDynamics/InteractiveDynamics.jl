using DataStructures
using DynamicalBilliards: ismagnetic, find_cyclotron

mutable struct ParticleObservable{P<:AbstractParticle{Float32}}
    # Fields necessary for simulation
    p::P   # particle
    i::Int # index of obstacle to be collided with
    tmin::Float32 # time to next collision
    t::Float32    # current time (resets at each collision)
    n::Int        # number of collisions done so far
    T::Float32    # total time
    # Fields used in plotting
    tail::Observable{CircularBuffer{Point2f0}}
    ξsin::Observable{Point2f0}
end
function ParticleObservable(p, bd, n, ξsin = Point2f0(0, 0)) # initializer
    i, tmin::Float32, cp = next_collision(p, bd)
    cb = CircularBuffer{Point2f0}(n)
    for i in 1:n; push!(cb, Point2f0(p.pos)); end
    ParticleObservable(p, i, tmin, 0f0, 0, 0f0, Observable.((cb, ξsin))...)
end
const ParObs = ParticleObservable

function rebind_partobs!(p::ParticleObservable, p0::AbstractParticle, bd, ξsin = nothing)
    i, tmin::Float32, cp = next_collision(p0, bd)
    ξ = sφ = 0f0 # TODO: Use boundary map on cp
    p.p.pos = p0.pos
    p.p.vel = p0.vel
    ismagnetic(p.p) && (p.p.center = find_cyclotron(p.p))
    p.i, p.tmin, p.t, p.n, p.T = i, tmin, 0f0, 0, 0f0
    L = length(p.tail[])
    append!(p.tail[], [Point2f0(p0.pos) for i in 1:L])
    p.tail[] = p.tail[]
    if ξsin ≠ nothing
        p.ξsin = ξsin # This can only be updated from bmap, which gives selection directly
    end
end

function animstep!(parobs, bd, dt, updateplot = true, intervals = nothing)
    if parobs.t + dt - parobs.tmin > 0
        rt = parobs.tmin - parobs.t # remaining time
        animbounce!(parobs, bd, rt, updateplot, intervals)
    else
        propagate!(parobs.p, dt)
        parobs.t += dt
        push!(parobs.tail[], parobs.p.pos)
        if updateplot
            parobs.tail[] = parobs.tail[] # trigger update
        end
    end
    return
end

function animbounce!(parobs, bd, rt, updateplot = true, intervals = nothing)
    propagate!(parobs.p, rt)
    DynamicalBilliards._correct_pos!(parobs.p, bd[parobs.i])
    DynamicalBilliards.resolvecollision!(parobs.p, bd[parobs.i])
    ismagnetic(parobs.p) && (parobs.p.center = find_cyclotron(parobs.p))
    if intervals ≠ nothing
        ξ, sφ = to_bcoords(parobs.p.pos, parobs.p.vel, bd[parobs.i])
        parobs.ξsin = (ξ, sφ)
    end
    i, tmin::Float32, = next_collision(parobs.p, bd)
    parobs.i = i
    parobs.tmin = tmin
    parobs.t = 0f0
    parobs.T += tmin
    parobs.n += 1
    push!(parobs.tail[], parobs.p.pos)
    if updateplot
        parobs.tail[] = parobs.tail[] # trigger update
    end
    return
end
