export ABMObservable

struct ABMObservable{M, AS, MS, AD, MD, ADF, MDF, W}
    model::M # this is an observable
    agent_step!::AS
    model_step!::MS
    adata::AD
    mdata::MD
    adf::ADF # this is an observable
    mdf::MDF # this is an observable
    s::Ref{Int}
    when::W
end

function Agents.step!(mobs::ABMObservable, n; kwargs...)
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

function Base.show(io::IO, ::ABMObservable)
    print(io,
"""
    mobs::ABMObservable
An object that contains all information necessary to step an agent based model
interactively. Calling `Agents.step!(mobs, n)` will step te model for `n`.
The fields `mobs.model, mobs.adf, mobs.mdf` are _observables_ that contain
the actual model, and then agent and model dataframes with collected data.
These observables are updated on stepping (when it makes sense).
All plotting and interactivity should be defined by `lift`ing these observables.
"""
)
end