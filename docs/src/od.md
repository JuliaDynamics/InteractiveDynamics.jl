# Interactive Orbit Diagram
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/odhenon.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_orbitdiagram
scaleod
```

For example, running

```
i = p_index = 1
ds, p_min, p_max, parname = Systems.standardmap(), 0.0, 1.2, "k"
t = "orbit diagram for the standard map"

oddata = interactive_orbitdiagram(ds, p_index, p_min, p_max, i;
                                  parname = parname, title = t)

ps, us = scaleod(oddata)
```

will produce

```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/odstandard.mp4?raw=true" type="video/mp4">
</video>
```
