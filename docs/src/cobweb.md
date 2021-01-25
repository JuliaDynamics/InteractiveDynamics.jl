# Interactive Cobweb Diagram
```@raw html
<video width="100%" height="auto" controls autoplay loop>
<source src="https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/cobweb.mp4?raw=true" type="video/mp4">
</video>
```

```@docs
interactive_cobweb
```

The animation at the top of this page was done with

```julia
using InteractiveDynamics, GLMakie, DynamicalSystems

# the second range is a convenience for intermittency example of logistic
rrange = 1:0.001:4.0
# rrange = (rc = 1 + sqrt(8); [rc, rc - 1e-5, rc - 1e-3])

lo = Systems.logistic(0.4; r=rrange[1])

interactive_cobweb(lo, rrange, 5)
```
