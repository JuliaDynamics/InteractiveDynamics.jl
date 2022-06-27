using Agents
using GLMakie
using InteractiveDynamics

zombie_model, zombie_step!, zombie_model_step! = Models.zombies()

aczombie(agent) = agent.infected ? (:green, 0.9) : (:purple, 0.75)
aszombie(agent) = agent.infected ? 15 : 12

axiskwargs = (; title = "Zombie outbreak", backgroundcolor = "#f3f3f3")
fig, ax, abmobs = abmplot(zombie_model; axiskwargs, ac = aczombie, as = aszombie)
fig

# %% with parameter sliders & time evolution
fig, ax, abmobs = abmplot(zombie_model; agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac = aczombie, as = aszombie, axiskwargs, params = Dict(:dt => 0.1:0.01:0.2),
    enable_inspection = false,
)
fig


# %% abmexploration convenience function
zombie_share(model) = count(model[id].infected for id in allids(model)) / nagents(model)
fig, abmobs = abmexploration(zombie_model;
    agent_step! = zombie_step!, model_step! = zombie_model_step!,
    ac = aczombie, as = aszombie, params = Dict(:dt => 0.01:0.001:0.02),
    adata = [(:infected, count)], mdata = [zombie_share, :dt],
    alabels = ["Number of\nZombies"], mlabels = ["Zombification %", "distance per step"],
    axiskwargs,
)

fig
