using DynamicalSystems, InteractiveChaos

i = 1
p_index = 1

systems = [(Systems.logistic(), 3.0, 4.0),
           (Systems.henon(), 0.8, 1.4),
           (Systems.standardmap(), 0.6, 1.2)]

ds, p_min, p_max = systems[1]

od_node = interactive_orbitdiagram(ds, i, p_index, p_min, p_max);
