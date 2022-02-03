using Agents
using OSMMakie
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
count_infected(model) = count(model[id].infected for id in allids(model))
p = abmplot!(zombie_model; ax, agent_step! = zombie_step!, model_step! = zombie_model_step!, 
    ac, as, params = Dict(:dt => 0.1:0.01:0.2), adata = [:infected])#, mdata = count_infected)
