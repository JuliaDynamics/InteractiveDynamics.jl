struct ParticleObservable
    i::Observable{Int}
    tmin::Observable{Float32}
    t::Observable{Float32}
    n::Observable{Int}
    T::Observable{Float32}
    tail::Observable{Vector{Point2f0}}
    pos::Observable{Point2f0}
    vel::Observable{Point2f0}
    ξsin::Observable{Point2f0}
end
function ParticleObservable(p, bd, n) # initializer
    i, tmin::Float32, cp = next_collision(p, bd)
    ξ = sφ = 0f0 # TODO: Use boundary map on cp
    ParticleObservable(Observable.((
        i, tmin, 0f0, 0, 0f0, [Point2f0(p.pos) for i in 1:n],
        Point2f0(p.pos), Point2f0(p.vel), Point2f0(ξ, sφ)
    ))...)
end
const ParObs = ParticleObservable

function animstep!(p, bd, dt, parobs)
    if parobs.t[] + dt - parobs.tmin[] > 0
        rt = parobs.tmin[] - parobs.t[] # remaining time
        animbounce!(p, bd, rt, parobs)
    else
        propagate!(p, dt)
        parobs.t[] += dt
        parobs.T[] += dt
        parobs.pos[] = p.pos
        parobs.vel[] = p.vel
        popfirst!(parobs.tail[])
        push!(parobs.tail[], p.pos)
        parobs.tail[] = parobs.tail[] # trigger update
    end
    return
end

function animbounce!(p, bd, rt, parobs)
    propagate!(p, rt)
    DynamicalBilliards._correct_pos!(p, bd[parobs.i[]])
    DynamicalBilliards.resolvecollision!(p, bd[parobs.i[]])
    i, tmin::Float32, = next_collision(p, bd)
    parobs.i[] = i
    parobs.tmin[] = tmin
    parobs.t[] = 0f0
    parobs.T[] += rt
    parobs.pos[] = p.pos
    parobs.vel[] = p.vel
    popfirst!(parobs.tail[])
    push!(parobs.tail[], p.pos)
    parobs.tail[] = parobs.tail[] # trigger update
    # TODO: adjust boundary map
    return
end
