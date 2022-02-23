function billiard_interactive(bd::Billiard, ps::Vector{<:AbstractParticle};
        add_controls = true,
        displayfigure = true,
        sleept = nothing,
        dt = 0.001,
        backgroundcolor = DEFAULT_BG,
        kwargs...
    )
    fig = Figure()
    dislayfigure && display(fig)
    ax = Axis(fig[1,1])
    if plot_bmap
        bmax = Axis(fig[1,2])
    else
        bmax = nothing
    end
    phs, chs = billiard_plotting_init!(ax, bd, ps; bmax, kwargs...)
    ######################################################################################
    # Controls and stepping
    # Controls and stuff are here so that a video function can be made easily;
    # the axis only initializes and binds the observables
    # TODO: Controls
    return phs, chs
end

function billiard_video(bd::Billiard, ps::Vector{<:AbstractParticle}; kwargs...)
    # TODO:
end
