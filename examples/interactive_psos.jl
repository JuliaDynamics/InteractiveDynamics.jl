using InteractiveChaos, Makie, OrdinaryDiffEq
diffeq = (alg = Vern9(), abstol = 1e-9, reltol = 1e-9)

ds = Systems.henonheiles()

potential(x, y) = 0.5(x^2 + y^2) + (x^2*y - (y^3)/3)
energy(x,y,px,py) = 0.5(px^2 + py^2) + potential(x,y)
const E = energy(get_state(ds)...)

function complete(y, py, x)
    V = potential(x, y)
    Ky = 0.5*(py^2)
    Ky + V ≥ E && error("Point has more energy!")
    px = sqrt(2(E - V - Ky))
    ic = [x, y, px, py]
    return ic
end

chaotic = get_state(ds)
stable = [0., 0.1, 0.5, 0.]

plane = (1, 0.0)

state, scene = interactive_poincaresos(ds, plane, (2, 4), complete;
markersizes = (-5, -1), diffeq...)

lines!(scene.children[2], [Point2f0(0.06465084105730057, -0.4 + 0.2*i) for i in 0:4]);
lines!(scene.children[2], [Point2f0(-0.3 + 0.15*i, -0.18481573462486267) for i in 0:6]);
display(scene);
