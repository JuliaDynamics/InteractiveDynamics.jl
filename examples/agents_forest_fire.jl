using Agents, Random
using Makie
using InteractiveChaos

cd(@__DIR__)

model, agent_step!, model_step! = Models.forest_fire()

alive(model) = count(a.status for a in allagents(model))
burning(model) = count(!a.status for a in allagents(model))
mdata = [alive, burning, nagents]
mlabels = ["alive", "burning", "total"]

params = Dict(
    :f => 0.02:0.01:1.0,
    :p => 0.01:0.01:1.0,
)

ac(a) = a.status ? "#1f851a" : "#67091b"
am = :rect

p1 = interactive_abm(model, agent_step!, model_step!, params;
ac = ac, as = 1, am = am, mdata = mdata, mlabels=mlabels)
