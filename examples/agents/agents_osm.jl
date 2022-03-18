using Agents
using GLMakie
using InteractiveDynamics

zombie_model, zombie_step!, zombie_model_step! = Models.zombies()

ac(agent) = agent.infected ? (:green, 0.9) : (:purple, 0.75)
as(agent) = agent.infected ? 10 : 8

## interactive app

axiskwargs = (; title = "Zombie outbreak", backgroundcolor = "#f3f3f3")

fig = Figure()
ax = Axis(fig[1,1]; axiskwargs...)
p = abmplot!(zombie_model; ax, agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac, as)
fig

## with parameter sliders

fig = Figure()
ax = Axis(fig[1,1]; axiskwargs...)
p = abmplot!(zombie_model; ax, agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac, as, params = Dict(:dt => 0.1:0.01:0.2))
fig

## with data collection

fig = Figure()
ax = Axis(fig[1,1]; axiskwargs...)
zombie_share(model) = count(model[id].infected for id in allids(model)) / nagents(model)
p = abmplot!(zombie_model; ax, agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac, as, params = Dict(:dt => 0.01:0.001:0.02),
    adata = [(:infected, count)], mdata = [zombie_share, :dt])

fig

## add custom plot

plot_layout = fig[:,end+1] = GridLayout()

xs = @lift($(p.adf).step)
infected = @lift($(p.adf).count_infected)
scatter(plot_layout[1,:], xs, infected)

xs = @lift($(p.mdf).step)
dt = @lift($(p.mdf).dt)
scatter(plot_layout[end+1,:], xs, dt)

share_zombies = @lift($(p.mdf).zombie_share)
scatterlines(plot_layout[end+1,:], xs, share_zombies)

fig



## abmexploration convenience function

fig, p = abmexploration(zombie_model;
    agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac, as, params = Dict(:dt => 0.01:0.001:0.02),
    adata = [(:infected, count)], mdata = [zombie_share, :dt],
    alabels = ["Number of\nZombies"], mlabels = ["Zombie share", "travel distance"],
    axiskwargs
)

fig
