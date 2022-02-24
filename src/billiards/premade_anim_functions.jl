######################################################################################
# Exported functions
######################################################################################
function bdplot_interactive(bd::Billiard, ps::Vector{<:AbstractParticle};
        playback_controls = true,
        dt = 0.001,
        plot_bmap = false,
        # backgroundcolor = DEFAULT_BG,
        kwargs...
    )
    fig = Figure()
    primary_layout = fig[1,1] = GridLayout()
    ax = Axis(primary_layout[1,1])
    if plot_bmap
        resize!(fig.scene, (2fig.scene.px_area[].widths[1], fig.scene.px_area[].widths[2]))
        intervals = DynamicalBilliards.arcintervals(bd)
        bmax = obstacle_axis!(fig[1,2], intervals)
    else
        bmax = nothing
        intervals = nothing
    end

    phs, chs = bdplot_plotting_init!(ax, bd, ps; bmax, kwargs...)
    ps0 = Observable(deepcopy(ps))

    if playback_controls
        control_observables = bdplot_animation_controls(fig, primary_layout)
        bdplot_control_actions!(fig, control_observables, phs, chs, bd, dt, ps0, intervals)
    end

    return fig, phs, chs
end

function bdplot_video(file, bd::Billiard, ps::Vector{<:AbstractParticle};
        dt = 0.001, frames = 1000, steps = 10, plot_bmap = false,
        framerate = 60, kwargs...
    )
    fig, phs, chs = bdplot_interactive(bd, ps; playback_controls = false, plot_bmap, kwargs...)
    intervals = !plot_bmap ? nothing : DynamicalBilliards.arcintervals(bd)
    record(fig, file, 1:frames; framerate) do j
        for _ in 1:steps-1
            bdplot_animstep!(phs, chs, bd, dt; update = false, intervals)
        end
        bdplot_animstep!(phs, chs, bd, dt; update = true, intervals)
    end
    return
end

######################################################################################
# Internal interaction code
######################################################################################
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

function bdplot_control_actions!(fig, control_observables, phs, chs, bd, dt, ps0, intervals)
    isrunning, resetbutton, runbutton, stepslider = control_observables

    on(runbutton) do clicks; isrunning[] = !isrunning[]; end
    on(runbutton) do clicks
    @async while isrunning[] # without `@async`, Julia "freezes" in this loop
    # for jjj in 1:1000
            n = stepslider[]
            for _ in 1:n-1
                bdplot_animstep!(phs, chs, bd, dt; update = false, intervals)
            end
            bdplot_animstep!(phs, chs, bd, dt; update = true, intervals)
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window.
            yield()
        end
    end

    # Whenever initial particles are changed, trigger reset update
    on(ps0) do ps
        phs_vals, chs_vals = helpers_from_particles(deepcopy(ps), bd, length(phs[][1].tail))
        phs[] = phs_vals
        chs[] = chs_vals
    end
    on(resetbutton) do clicks
        notify(ps0) # simply trigger initial particles change
    end

    # Selecting a line and making new particles
    ax = content(fig[1,1][1,1])
    MakieLayout.deactivate_interaction!(ax, :rectanglezoom)
    sline = select_line(ax.scene; color = JULIADYNAMICS_COLORS[1])
    dx = 0.001 # TODO: keyword
    ω0 = DynamicalBilliards.ismagnetic(ps0[][1]) ? ps0[][1].ω : nothing
    N = length(ps0[])
    on(sline) do val
        pos = val[1]
        dir = val[2] - val[1]
        φ = atan(dir[2], dir[1])
        ps0[] = DynamicalBilliards.particlebeam(pos..., φ, N, dx, ω0, eltype(bd))
    end

end

