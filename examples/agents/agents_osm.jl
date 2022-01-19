using Agents
using GLMakie
using InteractiveDynamics

zombie_model, zombie_step!, zombie_model_step! = Models.zombies()

ac(agent) = agent.infected ? (:green, 0.9) : (:purple, 0.75)
as(agent) = agent.infected ? 10 : 8

abm_play(
    zombie_model, zombie_step!, zombie_model_step!;
    ac, as,
    title = "Zombie outbreak"
)
