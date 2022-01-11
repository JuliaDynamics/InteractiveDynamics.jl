using Agents

model, zombie_step!, model_step! = Models.zombies()

using OSMMakie
using GLMakie
ac(agent) = agent.infected ? :green : :black
as(agent) = agent.infected ? 6 : 5
fig = Figure(); display(fig)
ax = Axis(fig[1,1])
osmplot!(ax, model.space.map)
ids = model.scheduler(model)
colors = Observable([ac(model[i]) for i in ids])
sizes = Observable([as(model[i]) for i in ids])
pos = Observable(Point2f[OSM.latlon(model[i].pos, model) for i in ids])
scatter!(ax, pos; color = colors, markersize = sizes)

# %%
record(fig, "outbreak.mp4", 1:200; framerate = 15) do i
    Agents.step!(model, agent_step!, 1)
    ids = model.scheduler(model)
    colors[] = [ac(model[i]) for i in ids]
    sizes[] = [as(model[i]) for i in ids]
    pos[] = Point2f[OSM.latlon(model[i].pos, model) for i in ids]
end