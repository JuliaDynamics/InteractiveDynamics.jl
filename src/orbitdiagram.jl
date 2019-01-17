using DynamicalSystemsBase, Makie, Interact, Blink, Colors

"""
    controlwindow(D, n, Ttr, density, i)
Create an Electron control window for the orbit diagram interactive application.

Return `n, Ttr, density, i, ▢update, ▢back, ▢reset`, all of which are `Observable`s.
Their value corresponds to the one chosen in the Electron window
(items with `▢` are buttons).
"""
function controlwindow(D, n, Ttr, density, i)
    n = Interact.textbox(string(n); value = n, label = "n")
    Ttr = Interact.textbox(string(Ttr); value = Ttr, label = "Ttr")
    density = Interact.textbox(string(density); value = density, label = "density")

    i = Interact.dropdown(OrderedDict(string(j) => j for j in 1:D); label = "variable")
    ▢update = Interact.button("update")
    ▢back = Interact.button("← back")
    ▢reset = Interact.button("reset")

    α = Interact.slider(0:0.001:1; value = 0.1, label = "α (transparency)")

    w = Window()
    s = 5em
    body!(w, Interact.vbox(
        α,
        Interact.hbox(n, Ttr, density),
        Interact.hbox(i, hskip(s), ▢update, hskip(s), ▢back, hskip(s), ▢reset)
        )
    )

    return n, Ttr, density, i, ▢update, ▢back, ▢reset, observe(α)
end

function set_limits!(scplot, r)
    AbstractPlotting.update_limits!(scplot, r)
    AbstractPlotting.scale_scene!(scplot)
    AbstractPlotting.center!(scplot)
    AbstractPlotting.update!(scplot)
end

function interactive_orbitdiagram(ds::DiscreteDynamicalSystem,
    i::Int, p_index, p_min, p_max;
    density = 1000, u0 = get_state(ds), Ttr = 200, n = 1000
    )

    # Initialization
    integ = integrator(ds)
    scene = Scene()
    pmin, pmax = p_min, p_max

    # UI elements
    n, Ttr, density, i, ▢update, ▢back, ▢reset, α =
    controlwindow(dimension(ds), n, Ttr, density, i)

    # Orbit diagram data
    od_node = Observable(
        minimal_od(integ, i[], p_index, pmin, pmax, density[], n[], Ttr[], u0)
    )
    # Scales for x and p:
    pdif = abs(pmax - pmin)
    xmin, xmax = extrema(o[2] for o in od_node[])
    xdif = abs(xmax - xmin)

    # History stores the variable index and diagram limits
    history = [(i[], pmin, pmax, xmin, xmax)]

    rval = 50.0 # to be sure points have reasonable size
    msize = Observable(min(pdif, xdif) / rval)

    color = lift(a -> RGBA(0,0,0,a), α)

    scplot = scatter(od_node, markersize = msize, color = color)
    display(scplot)
    rect = select_rectangle(scplot)

    on(rect) do r
        pmin, xmin = r.origin
        pmax, xmax = r.origin + r.widths
        msize[] = min(abs(pmax - pmin), abs(xmax - xmin)) / rval
        od_node[] = minimal_od(
            integ, i[],  p_index, pmin, pmax,
            density[], n[], Ttr[], u0, xmin, xmax
        )

        push!(history, (i[], pmin, pmax, xmin, xmax)) # update history
        set_limits!(scplot, r)
    end

    # Upon selecting new variable
    on(i) do j
        previ, pmin, pmax, xmin, xmax = history[end]
        od_node[] = minimal_od(integ, j, p_index, pmin, pmax, density[], n[], Ttr[], u0)
        xmin, xmax = extrema(o[2] for o in od_node[])

        msize[] = min(abs(pmax - pmin), abs(xmax - xmin)) / rval

        set_limits!(scplot, FRect(Point2f0(pmin, xmin), Point2f0(pmax-pmin,xmax-xmin)))
        push!(history, (j, pmin, pmax, xmin, xmax)) # update history
    end

    # Upon hitting the update button (no limits can change with update)
    on(▢update) do clicks
        j, pmin, pmax, xmin, xmax = history[end]
        od_node[] = minimal_od(integ, j, p_index, pmin, pmax, density[], n[], Ttr[], u0)
    end

    display(scplot)
    return od_node
end

function minimal_od(integ, i, p_index, pmin, pmax,
                    density::Int, n::Int, Ttr::Int, u0, xmin = -Inf, xmax = Inf)

    pvalues = range(pmin, stop = pmax, length = density)
    od = Vector{Point2f0}()
    @inbounds for p in pvalues
        DynamicalSystemsBase.reinit!(integ, u0)
        integ.p[p_index] = p
        DynamicalSystemsBase.step!(integ, Ttr)
        for z in 1:n
            DynamicalSystemsBase.step!(integ)
            x = integ.u[i]
            if xmin ≤ x ≤ xmax
                push!(od, Point2f0(p, integ.u[i]))
            end
        end
    end
    return od
end

ds = Systems.henon()
i = 1
p_index = 1
p_min = 0.8
p_max = 1.4

od_node = interactive_orbitdiagram(ds, i, p_index, p_min, p_max);

# TODO:
# add reset button that goes to the initial x0,p0
# add button to select which variable of the system is plotted
# make recomputation trigger each time one of the sliders is adjusted
