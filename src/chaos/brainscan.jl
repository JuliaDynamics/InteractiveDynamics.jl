export brainscan_poincaresos

# TODO: Would be nice to extend this to have multiple datasets...

"""
    brainscan_poincaresos(A::Dataset, j::Int)
Launch an interactive application for scanning a Poincare surface of section of `A`
like a "brain scan", where the plane that defines the section can be arbitrarily
moved around via a slider. Return `figure, ax3D, ax2D`.

The input dataset must be 3 dimensional, and here the crossing plane is always
chosen to be when the `j`-th variable of the dataset crosses a predefined value.
The slider automatically gets all possible values the `j`-th variable can obtain.

The keywords `linekw, scatterkw` are named tuples or dictionaries that are propagated to
as keyword arguments to the line
and scatter plot respectively, while the keyword `direction = -1` is propagated
to the function `DyamicalSystems.poincaresos`.
"""
function brainscan_poincaresos(
    tr::DynamicalSystems.AbstractDataset, j::Int;
    linekw = (), scatterkw = (color = :red,), direction = -1,
)

@assert size(tr, 2) == 3
@assert j ∈ 1:3
mi, ma = DynamicalSystems.minmaxima(tr)
otheridxs = DynamicalSystems.SVector(setdiff(1:3, j)...)

figure = Figure(resolution = (2000, 800))
display(figure)
ax = figure[1, 1] = Axis3(figure)
axp = figure[1, 2] = Axis(figure)
sll = labelslider!(
    figure, "$(('x':'z')[j]) =", range(mi[j], ma[j]; length = 100);
    sliderkw = Dict(:startvalue => (ma[j]+mi[j])/2)
)
figure[2, :] = sll.layout
y = sll.slider.value

# plot 3D trajectory
lines!(ax, tr.data; linekw...)

# plot transparent plane
ss = [mi...]
ws = [(ma - mi)...]
ws[j] = 0

p = lift(y) do y
    ss[j] = y
    o = Makie.Point3f0(ss...)
    w = Makie.Point3f0(ws...)
    Makie.FRect3D(o, w)
end

a = Makie.RGBAf0(0,0,0,0)
c = Makie.RGBAf0(0.2, 0.2, 1.0, 1.0)
img = Makie.ImagePattern([c a; a c]);
Makie.mesh!(ax, p; color = img);

# Poincare sos
psos = lift(y) do y
    DynamicalSystems.poincaresos(tr, (j, y); direction)
end
psos2d = lift(p -> p[:, otheridxs].data, psos)
psos3d = lift(p -> p.data, psos)

Makie.scatter!(axp, psos2d; scatterkw...)

ms = 25maximum(abs(ma[i] - mi[i]) for i in 1:3)
Makie.scatter!(ax, psos3d; markersize = ms, scatterkw...)

xlims!(axp, mi[otheridxs[1]], ma[otheridxs[1]])
ylims!(axp, mi[otheridxs[2]], ma[otheridxs[2]])

return figure, ax, axp

end
