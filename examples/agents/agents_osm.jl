using Agents
using OSMMakie
using GLMakie
using InteractiveDynamics

zombie_model, zombie_step!, zombie_model_step! = Models.zombies()

ac(agent) = agent.infected ? (:green, 0.9) : (:purple, 0.75)
as(agent) = agent.infected ? 10 : 8

fig = Figure()
ax = Axis(fig[1,1]; title = "Zombie outbreak")
abmplot!(zombie_model; ax, agent_step! = zombie_step!, model_step! = zombie_model_step!, 
    ac, as)
