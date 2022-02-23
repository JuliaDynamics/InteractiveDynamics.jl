function bdplot_interactive(bd::Billiard, ps::Vector{<:AbstractParticle};
        add_controls = true,
        sleept = nothing,
        dt = 0.001,
        plot_bmap = false,
        # backgroundcolor = DEFAULT_BG,
        kwargs...
    )
    fig = Figure()
    primary_layout = fig[1,1] = GridLayout()
    ax = Axis(primary_layout[1,1])
    if plot_bmap
        bmax = Axis(fig[1,2])
    else
        bmax = nothing
    end
    phs, chs = bdplot_plotting_init!(ax, bd, ps; bmax, kwargs...)
    ######################################################################################
    # Controls and stepping
    # Controls and stuff are here so that a video function can be made easily;
    # the axis only initializes and binds the observables
    # TODO: Controls
    control_observables = bdplot_animation_controls(fig, primary_layout)
    bdplot_control_actions!(control_observables, phs, chs, bd, dt)
    # billiard_animstep!(phs, chs, bd, dt; update = true)

    return fig, phs, chs
end

function bdplot_animation_controls(fig, primary_layout)
    control_layout = primary_layout[2,1] = GridLayout(tellheight = true, tellwidth = false)

    resetbutton = Button(fig;
        label = "reset", buttoncolor = RGBf(0.8, 0.8, 0.8),
        height = 40, width = 80
    )
    runbutton = Button(fig; label = "run",
        buttoncolor = RGBf(0.8, 0.8, 0.8), height = 40, width = 80
    )
    stepslider = labelslider!(fig, "steps", 1:100, startvalue=1)
    # put them in the layout
    control_layout[1,1] = resetbutton
    control_layout[1,2] = runbutton
    control_layout[1,3] = stepslider.layout
    isrunning = Observable(false)
    return isrunning, resetbutton.clicks, runbutton.clicks, stepslider.slider.value
end

function bdplot_control_actions!(control_observables, phs, chs, bd, dt)
    isrunning, resetbutton, runbutton, stepslider = control_observables

    on(runbutton) do clicks; isrunning[] = !isrunning[]; end
    on(runbutton) do clicks
        @async while isrunning[]
            n = stepslider[]
            for _ in 1:n-1
                # TODO: Tail length is affected by dt with current design...
                # TODO: I think the solution is to put the tail back
                # into the ParticleHelper
                billiard_animstep!(phs, chs, bd, dt; update = false)
            end
            billiard_animstep!(phs, chs, bd, dt; update = true)
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window.
            yield()
        end
    end


    # TODO:
end


function bdplot_video(bd::Billiard, ps::Vector{<:AbstractParticle}; kwargs...)
    # TODO:
end


# New example code:
using DynamicalBilliards, InteractiveDynamics, GLMakie

N = 100
colors = :dense
colors = [GLMakie.RGBAf(i/N, 0, 1 - i/N, 0.25) for i in 1:N]

# Uncomment any of the following to get the billiard you want:
bd = billiard_stadium()
# bd = billiard_mushroom()
# bd = billiard_hexagonal_sinai(0.5, 1.0)
# bd = billiard_sinai(0.25f0, 1f0, 1f0)
# bd = Billiard(Antidot(Float32[0, 0], 0.5f0, false))
# bd, = billiard_logo(T = Float32)

# ps = [MagneticParticle(1, 0.6 + 0.0005*i, 0, 1) for i in 1:N]
# ps = [Particle(1, 0.6 + 0.00005*i, 0) for i in 1:N]
ps = particlebeam(0.8, 0.6, π/4, N, 0.01, nothing)

fig, phs, chs = bdplot_interactive(bd, ps; tail_length = 100);
display(fig)
