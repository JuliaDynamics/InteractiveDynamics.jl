
function add_interaction!(fig, ax, abmplot)
    add_controls = !isnothing(abmplot.agent_step![]) || !isnothing(abmplot.model_step![])
    add_plots = !isempty(abmplot.adata[]) || !isempty(abmplot.mdata[])

    if add_controls
        @assert !isnothing(ax) "Need `ax` to add model controls."
        add_controls!(fig, abmplot.model, abmplot.agent_step![], abmplot.model_step![]; 
            spu = abmplot.spu[], add_plots)
    end

    if add_controls && add_plots
        @assert !isnothing(ax) "Need `ax` to add plots and parameter sliders."
        # add data exploration plots and param sliders to fig[:, end+1]
        add_plots!(fig, abmplot)
    end

    return nothing
end

function add_controls!(fig, model, agent_step!, model_step!; spu, add_plots)
    controllayout = fig[end+1, :] = GridLayout(tellheight = true)

    # Add steps-per-update slider
    spu_slider = labelslider!(fig, "spu =", spu; tellwidth = true)
    controllayout[1, :] = spu_slider.layout
    speed = spu_slider.slider.value

    # Add sleep slider
    if model[].space isa Agents.ContinuousSpace
        _s, _v = 0:0.01:1, 0
    else
        _s, _v = 0:0.01:2, 1
    end
    sleep_slider = labelslider!(fig, "sleep =", _s, sliderkw = Dict(:startvalue => _v))
    controllayout[2, :] = sleep_slider.layout
    slep = sleep_slider.slider.value
    
    # Add model control buttons
    step = Button(fig, label = "step")
    run = Button(fig, label = "run")
    reset = Button(fig, label = "reset")
    if add_plots
        update = Button(fig, label = "update")
        controllayout[3, :] = MakieLayout.hbox!(step, run, reset, update; tellwidth = false)
    else
        controllayout[3, :] = MakieLayout.hbox!(step, run, reset; tellwidth = false)
    end

    # Clicking the step button
    on(step.clicks) do c
        n = speed[]
        Agents.step!(model[], agent_step!, model_step!, n)
        model[] = model[] # trigger Observable
    end

    # Clicking the run button
    isrunning = Observable(false)
    on(run.clicks) do c; isrunning[] = !isrunning[]; end
    on(run.clicks) do c
        @async while isrunning[]
            n = speed[]
            Agents.step!(model[], agent_step!, model_step!, n)
            model[] = model[] # trigger Observable
            slep[] == 0 ? yield() : sleep(slep[])
            isopen(fig.scene) || break # crucial, ensures computations stop if closed window.
        end
    end

    # Clicking the reset button
    model0 = deepcopy(model[]) # backup initial model state
    on(reset.clicks) do c
        model[] = deepcopy(model0)
        Agents.step!(model[], agent_step!, model_step!, 0)
    end

    return nothing
end
