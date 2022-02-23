using DataStructures: CircularBuffer
######################################################################################
# Code outline
######################################################################################
BILLIARDS_ANIMATIONS_API = """
Expected inputs: vector of particles, a billiard, and optionally the output of
`arcintervals`, which initializes plotted elements related with the boundary map

Two helper structures for each particle:
1. `ParticleHelper`: Contains quantities that are updated each `dt` step,
   including particle itself
2. `CollisionHelper`: Contains quantities that are only updated each collision.

These two helpers are necessary to
split the simulation into real-time stepping, instead of the traditional
DynamicalBilliards.jl setup of discrete time stepping (1 step = 1 collision).

The main thing returned to the user are two observables, one having vector
of helpers (1) and the other having vector of helpers (2).
Every plotted element is lifted from these observables.

An exported high-level function `billiard_animstep!(phs, chs, bd, dt; update, intervals)`
progresses the simulation for one `dt` step. The user should be using this function for
custom-made animations. The only thing the `update` keyword does is:
`notify!(phs)`. The collision helper is always notified at collisions.
"""

######################################################################################
# Struct definitions
######################################################################################
mutable struct ParticleHelper{P, T<:Real}
    p::P           # particle
    t::T           # time ellapsed (resets at each collision)
    T::T           # total time ellapsed (only resets when resetting particles)
end

mutable struct CollisionHelper{T<:Real}
    i::Int         # index of obstacle to be collided with
    tmin::T        # time to next collision
    n::Int         # total collisions so far
    ξsinφ::SVector{2, T}  # boundary map point
end

function helpers_from_particle(p::AbstractParticle, bd::Billiard, intervals = nothing)
    T = eltype(p.pos)
    i, tmin, _ = DynamicalBilliards.next_collision(p, bd)
    # Boundary coordinates
    if !isnothing(intervals)
        p2 = propagate!(copy(p), tmin)
        ξ, sinφ = to_bcoords(p2.pos, p2.vel, bd[i])
        ξsin = SVector(ξ, sinφ)
    else
        ξsin = SVector{2, T}(0, 0)
    end
    return ParticleHelper{typeof(p), T}(p, 0, 0), CollisionHelper{T}(i, tmin, 0, ξsin)
end

function helpers_from_particles(
    ps::Vector{P}, bd::Billiard, intervals = nothing) where {P<:AbstractParticle}
    T = eltype(ps[1])
    phs = ParticleHelper{P, T}[]
    chs = CollisionHelper{T}[]
    for i in 1:length(ps)
        ph, ch = helpers_from_particle(ps[i], bd, intervals)
        push!(phs, ph); push!(chs, ch)
    end
    return Observable(phs), Observable(chs)
end



######################################################################################
# Stepping functions
######################################################################################
function billiard_animstep!(phs, chs, bd, dt; update = false, intervals = nothing)
    phs_val = phs[]; chs_val = chs[]
    N = length(phs_val)
    any_collided = false
    for i in 1:N
        collided = billiard_animstep!(phs_val[i], chs_val[i], bd, dt, intervals)
        any_collided = collided || any_collided
    end
    update && notify(phs)
    any_collided && notify(chs)
    return
end

function billiard_animstep!(ph::ParticleHelper, ch::CollisionHelper, bd, dt, intervals)
    collided = false
    if ph.t + dt - ch.tmin > 0
        # We reach the collision poin within the `dt` window, so we need to
        # call the "bounce" logic
        rt = ch.tmin - ph.t # remaining time to collision
        billiards_animbounce!(ph, ch, bd, rt, intervals)
        dt = dt - rt # remaining dt to propagate for
        collided = true
    end
    DynamicalBilliards.propagate!(ph.p, dt)
    ph.t += dt
    ph.T += dt
    return collided
end

function billiards_animbounce!(ph::ParticleHelper, ch::CollisionHelper, bd, rt, intervals)
    # Bring to collision and resolve it:
    DynamicalBilliards.propagate!(ph.p, rt)
    DynamicalBilliards._correct_pos!(ph.p, bd[ch.i])
    DynamicalBilliards.resolvecollision!(ph.p, bd[ch.i])
    DynamicalBilliards.ismagnetic(ph.p) && (ph.p.center = DynamicalBilliards.find_cyclotron(ph.p))
    # Update all remaining counters
    i, tmin, = DynamicalBilliards.next_collision(ph.p, bd)
    ch.i = i
    ch.tmin = tmin
    ch.n += 1
    ph.t = 0
    ph.T += rt
    # Compute new boundary map point if necessary
    if !isnothing(intervals)
        ξ, sφ = DynamicalBilliards.to_bcoords(ph.p.pos, ph.p.vel, bd[parobs.i])
        ξ += intervals[ph.i]
        ch.ξsin = SVector(ξ, sφ)
    end
    return
end


######################################################################################
# Initialization of observables and their plots
######################################################################################
function billiard_plotting_init!(ax::Axis, bd::Billiard, ps::Vector{<:AbstractParticle};
        tail_length = 1000, colors = JULIADYNAMICS_CMAP,
        fade = true,
        tailwidth = 1,
        plot_particles = true,
        particle_size = 5.0, # size of marker for scatter plot of particle balls
        velocity_size = 0.05, # size of multiplying the quiver
        bmax = nothing, intervals = nothing,
    )

    bdplot!(ax, bd)
    N = length(ps)
    cs = if !(colors isa Vector) || length(colors) ≠ N
        colors_from_map(colors, N, 0.8)
    else
        to_color.(colors)
    end
    # Instantiate the helper observables
    phs, chs = helpers_from_particles(ps, bd)


    ######################################################################################
    # Initialize plot elements and link them via Observable pipeline
    # Tail circular data:
    tails = [CircularBuffer{Point2f}(tail_length) for i in 1:N]
    for (i, p) ∈ enumerate(ps); fill!(tails[i], Point2f(p.pos)); end
    tails = Observable.(tails)
    # Plot tails
    for i in 1:N
        x = to_color(cs[i])
        if fade
            x = [RGBAf(x.r, x.g, x.b, i/tail_length) for i in 1:tail_length]
        end
        lines!(ax, tails[i]; color = x, linewidth = tailwidth)
    end
    # Trigger tail updates (we need `on`, can't use `lift`, coz of `push!` into buffer)
    on(phs) do phs
        for i in 1:length(phs)
            push!(tails[i][], phs[i].p.pos)
        end
        notify.(tails)
    end

    # Particles and their quiver
    if plot_particles # plot ball and arrow as a particle
        balls = lift(phs -> [Point2f(ph.p.pos) for ph in phs], phs)
        vels = lift(phs -> [Point2f(velocity_size*ph.p.vel) for ph in phs], phs)
        scatter!(
            ax, balls; color = darken_color.(cs),
            markersize = particle_size, strokewidth = 0.0,
        )
        arrows!(
            ax, balls, vels; arrowcolor = darken_color.(cs),
            linecolor = darken_color.(cs),
            normalize = false,
            # arrowsize = particle_size*vr/3,
            linewidth  = 2,
        )
    end

    # TODO: boundary map observable lifint and plotting
    # TODO: must return tails for resetting them.
    return phs, chs
end

