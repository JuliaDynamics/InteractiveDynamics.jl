"""
    mobs::ModelObservable
A sruct that contains all information necessary to step a model interactively. Calling
`Agents.step!(mobs, n)` will step te model for `n`.
The fields `mobs.model, mobs.adf, mobs.mdf` are _observables_ that are updated on stepping.
All plotting and interactivity should be defined by `lift`ing these observables.
"""
struct ModelObservable{M, AS, MS, AD, MD, ADF, MDF, W}
    model::M
    agent_step!::AS
    model_step!::MS
    adata::AD
    mdata::MD
    adf::ADF
    mdf::MDF
    s::Ref{Int}
    when::W
end

function Agents.step!(mobs::ModelObservable, n; kwargs...)
    model, adf, mdf = mobs.model, mobs.adf, mobs.mdf
    Agents.step!(model[], mobs.agent_step!, mobs.model_step!, n; kwargs...)
    notify(model)
    mobs.s[] = mobs.s[] + n # increment step counter
    if Agents.should_we_collect(mobs.s, model[], mobs.when)
        if !isnothing(mobs.adata)
            Agents.collect_agent_data!(adf[], model[], mobs.adata, mobs.s[])
            notify(adf)
        end
        if !isnothing(mdata)
            Agents.collect_model_data!(mdf[], model, mobs.mdata, mobs.s[])
            notify(mdf)
        end
    end
    return nothing
end
