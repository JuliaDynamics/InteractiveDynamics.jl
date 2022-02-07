using Agents
using GLMakie
using InteractiveDynamics

zombie_model, zombie_step!, zombie_model_step! = Models.zombies()

ac(agent) = agent.infected ? (:green, 0.9) : (:purple, 0.75)
as(agent) = agent.infected ? 10 : 8

## interactive app

fig = Figure()
ax = Axis(fig[1,1]; title = "Zombie outbreak")
p = abmplot!(zombie_model; ax, agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac, as)

## with parameter sliders

fig = Figure()
ax = Axis(fig[1,1]; title = "Zombie outbreak")
p = abmplot!(zombie_model; ax, agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac, as, params = Dict(:dt => 0.1:0.01:0.2))

## with data collection

fig = Figure()
ax = Axis(fig[1,1]; title = "Zombie outbreak")
zombie_share(model) = count(model[id].infected for id in allids(model)) / nagents(model)
p = abmplot!(zombie_model; ax, agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac, as, params = Dict(:dt => 0.01:0.001:0.02),
    adata = [:infected], mdata = [zombie_share, :dt])

fig

## add custom plot

plot_layout = fig[:,end+1] = GridLayout()

xs = @lift($(p.mdf).step)
dt = @lift($(p.mdf).dt)
scatter(plot_layout[1,1], xs, dt)

infected = @lift($(p.mdf).zombie_share)
lines(plot_layout[2,1], xs, infected)

## abm_data_exploration convenience function

fig, p = abm_data_exploration(zombie_model;
    agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac, as, params = Dict(:dt => 0.01:0.001:0.02),
    adata = [(:infected, count)], mdata = [zombie_share, :dt],
    alabels = ["Number of\nZombies"], mlabels = ["Zombie share", "travel distance"]
)

fig
