struct ABMStepper{AS, MS, X, C, M, S, O}
    agent_step!::AS
    model_step!::MS
    scheduler::X
    ac::C
    am::M
    as::S
    offset::O
    pos::Observable
    colors::Observable
    sizes::Observable
    markers::Observable
end


# If n = 0, it updates the plotted quantities without
# doing any stepping (useful when the model parameters have been updated
# or the reset button has been used)
function abm_interactive_step!(abmstepper, model, n::Int)
    astep! = abmstepper.agent_step!
    mstep! = abmstepper.model_step!
    sched = abmstepper.scheduler
    ac, am, as = getproperty.(abmstepper, (:ac, :am, :as))
    offset = abmstepper.offset
    pos, colors, sizes, markers = getproperty.(abmstepper, (:pos, :colors, :sizes, :markers))

    abm_interactive_stepping(
        model, astep!, mstep!, n, sched,
        pos, colors, sizes, markers, ac, as, am, offset
    )
end

function abm_interactive_stepping(
        model, agent_step!, model_step!, n, scheduler,
        pos, colors, sizes, markers, ac, as, am, offset
    )
    Agents.step!(model, agent_step!, model_step!, n)
    ids = scheduler(model)
    update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am, offset)
    return nothing
end

function update_abm_plot!(
        pos, colors, sizes, markers, model, ids, ac, as, am, offset
    )
    if Agents.nagents(model) == 0
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
