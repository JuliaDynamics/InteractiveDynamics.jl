using InteractiveChaos, Makie
using DynamicalSystems

i = 1
p_index = 1

systems = [(Systems.logistic(), 2.5, 4.0, "r", "logistic map"),
           (Systems.henon(), 0.8, 1.4, "a", "Hénon map"),
           (Systems.standardmap(), 0.0, 1.2, "k", "standard map")]

ds, p_min, p_max, parname, t = systems[2]
t = "orbit diagram for the "*t

oddata = interactive_orbitdiagram(ds, p_index, p_min, p_max, i;
                                  parname = parname, title = t)

ps, us = scaleod(oddata)
