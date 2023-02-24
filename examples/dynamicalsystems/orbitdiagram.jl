using DynamicalSystems
using InteractiveDynamics, GLMakie

i = 1

ds = Systems.lorenz()
pmap = PoincareMap(ds, (2, 0.0); rootkw = (xrtol = 1e-8, atol = 1e-9))

systems = [(Systems.logistic(), 2.5, 4.0, "r", "logistic map", 1),
           (Systems.henon(), 0.8, 1.4, "a", "Hénon map", 1),
           (Systems.standardmap(), 0.0, 1.2, "k", "standard map", 1),
           # Poincare map
           (pmap, 100.0, 200.0, "ρ", "Lorenz Poincare map", 2),
           # Stroboscopic map of duffing

]

ds, p_min, p_max, parname, t, p_index = systems[4]
t = "orbit diagram for the "*t

fig, oddata = interactive_orbitdiagram(ds, p_index, p_min, p_max, i;
                                  parname = parname, title = t)

ps, us = scaleod(oddata)
