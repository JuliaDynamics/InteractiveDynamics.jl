using DataStructures
using DynamicalBilliards: ismagnetic, find_cyclotron

mutable struct ParticleObservable{P<:AbstractParticle{Float32}}
    # Fields necessary for simulation
    p::P
    i::Int
    tmin::Float32
    t::Float32
    n::Int
    T::Float32
    # Fields used in plotting
    tail::Observable{CircularBuffer{Point2f0}}
    pos::Observable{Point2f0}
    vel::Observable{Point2f0}
    ξsin::Observable{Point2f0}
end
function ParticleObservable(p, bd, n) # initializer
    i, tmin::Float32, cp = next_collision(p, bd)
    ξ = sφ = 0f0 # TODO: Use boundary map on cp
    cb = CircularBuffer{Point2f0}(n)
    append!(cb, [Point2f0(p.pos) for i in 1:n])
    ParticleObservable(p, i, tmin, 0f0, 0, 0f0, Observable.((
        cb, Point2f0(p.pos), Point2f0(p.vel), Point2f0(ξ, sφ)
    ))...)
end
const ParObs = ParticleObservable

function animstep!(parobs, bd, dt, updateplot = true)
    if parobs.t + dt - parobs.tmin > 0
        rt = parobs.tmin - parobs.t # remaining time
        animbounce!(parobs, bd, rt, updateplot)
    else
        propagate!(parobs.p, dt)
        parobs.t += dt
        parobs.T += dt
        push!(parobs.tail[], parobs.p.pos)
        if updateplot
            parobs.pos[] = parobs.p.pos
            parobs.vel[] = parobs.p.vel
            parobs.tail[] = parobs.tail[] # trigger update
        end
    end
    return
end

function animbounce!(parobs, bd, rt, updateplot = true)
    propagate!(parobs.p, rt)
    DynamicalBilliards._correct_pos!(parobs.p, bd[parobs.i])
    DynamicalBilliards.resolvecollision!(parobs.p, bd[parobs.i])
    ismagnetic(parobs.p) && (parobs.p.center = find_cyclotron(parobs.p))
    i, tmin::Float32, = next_collision(parobs.p, bd)
    parobs.i = i
    parobs.tmin = tmin
    parobs.t = 0f0
    parobs.T += rt
    parobs.n += 1
    push!(parobs.tail[], parobs.p.pos)
    if updateplot
        parobs.pos[] = parobs.p.pos
        parobs.vel[] = parobs.p.vel
        parobs.tail[] = parobs.tail[] # trigger update
    end
    # TODO: adjust boundary map
    return
end
