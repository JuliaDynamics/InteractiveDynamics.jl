export brainscan_poincaresos

function brainscan_poincaresos(
    tr::DynamicalSystems.AbstractDataset, j::Int;
    linekw = (), scatterkw = (color = :red,), direction = -1,
)

mi, ma = DynamicalSystems.minmaxima(tr)
otheridxs = DynamicalSystems.SVector(setdiff(1:3, j)...)

scene, layout = layoutscene(resolution = (2000, 800))
display(scene)
ax = layout[1, 1] = LScene(scene)
axp = layout[1, 2] = LAxis(scene)
sll = labelslider!(
    scene, "p =", range(mi[j], ma[j]; length = 100);
    sliderkw = Dict(:startvalue => (ma[j]+mi[j])/2)
)
layout[2, :] = sll.layout
y = sll.slider.value

# plot 3D trajectory
lines!(ax, tr.data; linekw...)

# plot transparent plane
ss = [mi...]
ws = [(ma - mi)...]
ws[j] = 0

p = lift(y) do y
    ss[j] = y
    o = AbstractPlotting.Point3f0(ss...)
    w = AbstractPlotting.Point3f0(ws...)
    AbstractPlotting.FRect3D(o, w)
end

a = AbstractPlotting.RGBAf0(0,0,0,0)
c = AbstractPlotting.RGBAf0(0.2, 0.2, 1.0, 1.0)
img = AbstractPlotting.ImagePattern([c a; a c]);
AbstractPlotting.mesh!(ax, p; color = img);

# Poincare sos
psos = lift(y) do y
    DynamicalSystems.poincaresos(tr, (j, y); direction)
end
psos2d = lift(p -> p[:, otheridxs].data, psos)
psos3d = lift(p -> p.data, psos)

AbstractPlotting.scatter!(axp, psos2d; scatterkw...)

ms = 25maximum(abs(ma[i] - mi[i]) for i in 1:3)
AbstractPlotting.scatter!(ax, psos3d; markersize = ms, scatterkw...)

xlims!(axp, mi[otheridxs[1]], ma[otheridxs[1]])
ylims!(axp, mi[otheridxs[2]], ma[otheridxs[2]])

return scene, ax, axp

end
