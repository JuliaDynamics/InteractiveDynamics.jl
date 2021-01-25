using InteractiveDynamics, GLMakie, DynamicalSystems

# the second range is a convenience for intermittency example of logistic
rrange = 1:0.001:4.0
# rrange = (rc = 1 + sqrt(8); [rc, rc - 1e-5, rc - 1e-3])

lo = Systems.logistic(0.4; r=rrange[1])

interactive_cobweb(lo, rrange, 5)
