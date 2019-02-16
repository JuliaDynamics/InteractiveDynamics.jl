using InteractiveChaos, Makie

i = 1
p_index = 1

systems = [(Systems.logistic(), 2.5, 4.0, "r"),
           (Systems.henon(), 0.8, 1.4, "a"),
           (Systems.standardmap(), 0.6, 1.2, "k")]

ds, p_min, p_max, parname = systems[1]

oddata = interactive_orbitdiagram(
                             ds, i, p_index, p_min, p_max;
                             parname = parname, n = 100)

ps, us = scaleod(oddata...)
