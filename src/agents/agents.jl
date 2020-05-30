export interactive_abm

# TODO: Make run button togglable

function interactive_abm(
        model, agent_step!, model_step!, params;
        ac = "#765db4",
        as = 1,
        am = :circle,
        scheduler = model.scheduler,
        offset = nothing,
        spu = 1:100,
        mdata = nothing,
        adata = nothing,
        alabels = nothing,
        mlabels = nothing,
        when = true,
        equalaspect = true,
        kwargs...
    )

    # initialize data collection stuff stuff
    !isnothing(adata) && @assert adata[1] isa Tuple "Only aggregated agent data are allowed."
    !isnothing(alabels) && @assert length(alabels) == length(adata)
    !isnothing(mlabels) && @assert length(mlabels) == length(mdata)
    df_agent = Agents.init_agent_dataframe(model, adata)
    df_model = Agents.init_model_dataframe(model, mdata)
    L = (isnothing(adata) ? 0 : size(df_agent)[2]-1) + (isnothing(mdata) ? 0 : size(df_model)[2]-1)
    s = 0 # current step

    # Initialize main layout and abm axis
    scene, layout = layoutscene(resolution = (1200, 600 + L*100))
    abmax = layout[1,1] = LAxis(scene)
    xlims!(abmax, 0, model.space.extend[1])
    ylims!(abmax, 0, model.space.extend[2])
    equalaspect && (abmax.aspect = AxisAspect(1))

    # initialize abm plot stuff
    ids = scheduler(model)
    colors = ac isa Function ? Observable(to_color.([ac(model[i]) for i in ids])) : to_color(ac)
    sizes  = as isa Function ? Observable([as(model[i]) for i in ids]) : as
    markers= am isa Function ? Observable([am(model[i]) for i in ids]) : am
    if offset == nothing
        pos = Observable([model[i].pos for i in ids])
    else
        pos = Observable([model[i].pos .+ offset(model[i]) for i in ids])
    end

    # Initialize ABM interactive platform + parameter sliders
    scatter!(abmax, pos;
    color = colors, markersize = sizes, marker = markers)
    controllayout = layout[1, 2] = GridLayout(tellheight = false)
    slidervals, run, update, spuslider, sleslider = make_abm_controls =
    make_abm_controls!(scene, controllayout, model, params, spu)

    # Initialize data plots
    if L > 0
        N = Observable([0]) # steps that data are recorded at.
        data, axs = init_data_plots!(scene, layout, model, df_agent, df_model, adata, mdata, N, alabels, mlabels)
    end

    # Running the simulation:
    isrunning = Observable(false)
    on(run) do clicks; isrunning[] = !isrunning[]; end
    on(run) do clicks
        @async while isrunning[]
            n = spuslider[]
            Agents.step!(model, agent_step!, model_step!, n)
            if L > 0
                s += n
                if Agents.should_we_collect(s, model, when) # update collected data
                    push!(N.val, s)
                    update_data_plots!(data, axs, model, df_agent, df_model, adata, mdata, N)
                end
            end

            ids = scheduler(model)
            update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am, offset)
            sleslider[] == 0 ? yield() : sleep(sleslider[])
            isopen(scene) || break # crucial, ensures computations stop if closed window.
        end
    end

    # Clicking the update button:
    on(update) do clicks
        if isrunning[]
            isrunning[] = false
            update_abm_parameters!(model, params, slidervals)
            run[] = run[] + 1
        else
            update_abm_parameters!(model, params, slidervals)
        end
    end

    display(scene)
    return scene, df_agent, df_model
end

function init_data_plots!(scene, layout, model, df_agent, df_model, adata, mdata, N, alabels, mlabels)
    Agents.collect_agent_data!(df_agent, model, adata, 0)
    Agents.collect_model_data!(df_model, model, mdata, 0)
    La = isnothing(adata) ? 0 : size(df_agent)[2]-1
    Lm = isnothing(mdata) ? 0 : size(df_model)[2]-1
    data, axs = [], []
    datalayout = layout[2, :] = GridLayout()

    # Plot all quantities
    # TODO: make scatter+line plot 1.
    # TODO: make markers in pixel units.
    for i in 1:La
        x = Agents.aggname(adata[i])
        val = Observable([df_agent[end, x]])
        push!(data, val)
        ax = datalayout[i, :] = LAxis(scene)
        push!(axs, ax)
        ax.ylabel = isnothing(alabels) ? x : alabels[i]
        c = JULIADYNAMICS_COLORS[mod1(i, 3)]
        lines!(ax, N, val, color = c)
        scatter!(ax, N, val, marker = MARKER, markersize = 5AbstractPlotting.px, color = c)
    end
    for i in 1:Lm
        x = Agents.aggname(mdata[i])
        val = Observable([df_model[end, x]])
        push!(data, val)
        ax = datalayout[i+La, :] = LAxis(scene)
        push!(axs, ax)
        ax.ylabel = isnothing(mlabels) ? x : mlabels[i]
        c = JULIADYNAMICS_COLORS[mod1(i+La, 3)]
        lines!(ax, N, val, color = c)
        scatter!(ax, N, val, marker = MARKER, markersize = 5AbstractPlotting.px, color = c)
    end
    # Link axis
    if La+Lm > 1
        linkxaxes!(axs...)
        for ax in @view(axs[1:end-1]); hidexdecorations!(ax, grid = false); end
    end
    axs[end].xlabel = "step"
    return data, axs
end

function update_data_plots!(data, axs, model, df_agent, df_model, adata, mdata, N)
    Agents.collect_agent_data!(df_agent, model, adata, N[][end])
    Agents.collect_model_data!(df_model, model, mdata, N[][end])
    La = isnothing(adata) ? 0 : size(df_agent)[2]-1
    Lm = isnothing(mdata) ? 0 : size(df_model)[2]-1

    for i in 1:La
        o = data[i]
        x = Agents.aggname(adata[i])
        val = df_agent[end, x]
        push!(o[], val)
        o[] = o[] #update plot
    end
    for i in 1:Lm
        o = data[i+La]
        x = Agents.aggname(mdata[i])
        val = df_model[end, x]
        push!(o[], val)
        o[] = o[] #update plot
    end
    # TODO: Maybe we can optimize this by setting the limits ourselves (we have the data)
    for ax in axs; autolimits!(ax); end
end

function update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am, offset)
    if nagents(model) == 0
        @warn "The model has no agents, we can't plot anymore!"
        error("The model has no agents, we can't plot anymore!")
    end
    if offset == nothing
        pos[] = [model[i].pos for i in ids]
    else
        pos[] = [model[i].pos .+ offset(model[i]) for i in ids]
    end
    if ac isa Function; colors[] = to_color.([ac(model[i]) for i in ids]); end
    if as isa Function; sizes[] = [as(model[i]) for i in ids]; end
    if am isa Function; markers[] = [am(model[i]) for i in ids]; end
end

function make_abm_controls!(scene, controllayout, model, params, spu)
    firstrow = controllayout[1, :] = GridLayout(tellheight = false, tellwidth=false)
    run = LButton(scene, label = "run")
    update = LButton(scene, label = "update")
    firstrow[1, 1] = run
    firstrow[2, 1] = update
    spusl = labelslider!(scene, "spu =", spu)
    slesl = labelslider!(scene, "sleep =", 0:0.01:2)
    firstrow[1, 2] = spusl.layout
    firstrow[2, 2] = slesl.layout

    slidervals = Dict{Symbol, Observable}()
    for (i, (l, vals)) in enumerate(params)
        startvalue = get(model.properties, l, vals[1])
        sll = labelslider!(scene, string(l), vals; sliderkw = Dict(:startvalue => startvalue))
        slidervals[l] = sll.slider.value # directly add the observable
        controllayout[i+2, :] = sll.layout
    end
    return slidervals, run.clicks, update.clicks, spusl.slider.value, slesl.slider.value
end

function update_abm_parameters!(model, params, slidervals)
    for l in keys(slidervals)
        v = slidervals[l][]
        model.properties[l] = v
    end
end
