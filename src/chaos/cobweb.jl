export interactive_cobweb

"""
    interactive_cobweb(ds::DiscreteDynamicalSystem, prange, O::Int = 3; kwargs...)
Launch an interactive application for exploring cobweb diagrams of 1D discrete
dynamical systems. Two slides control the length of the plotted trajectory and the
current parameter value. The parameter values are obtained from the given `prange`.

In the cobweb plot, higher order iterates of the dynamic rule `f` are plotted as well,
starting from order 1 all the way to the given order `O`.
Both the trajectory in the cobweb, as well as any iterate `f` can be turned off by
using some of the buttons.

## Keywords
* `fkwargs = [(linewidth = 4.0, color = randomcolor()) for i in 1:O]`: plotting keywords
  for each of the plotted iterates of `f`
* `trajcolor = :black`: color of the trajectory
* `pname = "p"`: name of the parameter slider
* `pindex = 1`: parameter index
* `xmin = 0, xmax = 1`: limits the state of the dynamical system can take
* `Tmax = 1000`: maximum trajectory length
* `x0s = range(xmin, xmax; length = 101)`: Possible values for the x0 slider.
"""
function interactive_cobweb(
    ds, prange, O::Int = 3;
    fkwargs = [(linewidth = 4.0, color = randomcolor()) for i in 1:O],
    trajcolor = :black,
    pname = "p",
    xmin = 0.0,
    xmax = 1.0,
    Tmax = 1000,
    pindex = 1,
    x0s = range(xmin, xmax; length = 101),
)

@assert O ≥ 1
xs = range(xmin, xmax; length = 5000)

figure = Figure(resolution = (1000, 800))
axts = figure[1, :] = Axis(figure)
axmap = figure[2, :] = Axis(figure)

slr = labelslider!(figure, "$pname =", prange)
figure[3, :] = slr.layout
r_observable = slr.slider.value

sln = labelslider!(figure, "n =", 1:Tmax; sliderkw = Dict(:startvalue => 20))
figure[4, :] = sln.layout
L = sln.slider.value

sln = labelslider!(figure, "x₀ =", x0s; sliderkw = Dict(:startvalue => ds.u0))
figure[5, :] = sln.layout
x0 = sln.slider.value

# Timeseries plot
function seriespoints(x)
    n = 0:length(x)+1
    return [Point2f(n[i], x[i]) for i in 1:length(x)]
end

x = Observable(DynamicalSystems.trajectory(ds, L[], x0[]))
xn = lift(a -> seriespoints(a), x)
lines!(axts, xn; color = trajcolor, lw = 2.0)
scatter!(axts, xn; color = trajcolor, markersize = 10)
xlims!(axts, 0, 20) # this is better than autolimits
ylims!(axts, xmin, xmax)

# Cobweb diagram
DynamicalSystems.set_parameter!(ds, pindex, prange[1])

fobs = Any[Observable(ds.f.(xs, Ref(ds.p), 0))]
for order in 2:O
    push!(fobs, Observable(ds.f.(fobs[end][], Ref(ds.p), 0)))
end

# plot diagonal and fⁿ
lines!(axmap, [xmin,xmax], [xmin,xmax]; linewidth = 2, color = :gray, linestyle=:dash)
fcurves = Any[]
for i in 1:O
    _c = lines!(axmap, xs, fobs[i]; fkwargs[i]...)
    push!(fcurves, _c)
end

cobs = lift(a -> cobweb(a), x)
ccurve = lines!(axmap, cobs; color = (trajcolor, 0.5))
# cscatter = scatter!(axmap, cobs; color = trajcolor, markersize = 2)

xlims!(axmap, xmin, xmax)
ylims!(axmap, xmin, xmax)

# On trigger r-slider update all plots:
on(r_observable) do r
    DynamicalSystems.set_parameter!(ds, pindex, r)
    x[] = DynamicalSystems.trajectory(ds, L[], x0[])
    fobs[1][] = ds.f.(xs, Ref(ds.p), 0)
    for order in 2:O
        fobs[order][] = ds.f.(fobs[order-1][], Ref(ds.p), 0)
    end
end

on(L) do l
    x[] = DynamicalSystems.trajectory(ds, l, x0[])
    xlims!(axts, 0, l) # this is better than autolimits
end

on(x0) do u
    x[] = DynamicalSystems.trajectory(ds, L[], u)
end

# Finally add buttons to hide/show elements of the plot
cbutton = Button(figure; label = "cobweb")
fbuttons = Any[]
for i in 1:O
    _b = Button(figure; label = "f$(superscript(i))")
    push!(fbuttons, _b)
end
figure[6, :] = buttonlayout = GridLayout(tellwidth = false)
buttonlayout[:, 1:O+1] = [cbutton, fbuttons...]

# And add triggering for buttons
on(cbutton.clicks) do click
    ccurve.attributes.visible = !(ccurve.attributes.visible[])
    # cscatter.attributes.visible = !(cscatter.attributes.visible[])
end

for i in 1:O
    on(fbuttons[i].clicks) do click
        fcurves[i].attributes.visible = !(fcurves[i].attributes.visible[])
    end
end

display(figure)
return figure
end

function cobweb(t) # transform timeseries x into cobweb (point2D)
    # TODO: can be optimized to become in-place instead of pushing
    c = Point2f[]
    sizehint!(c, 2length(t))
    push!(c, Point2f(t[1], 0))
    for i ∈ 1:length(t)-1
        push!(c, Point2f(t[i], t[i]))
        push!(c, Point2f(t[i], t[i+1]))
    end
    return c
end