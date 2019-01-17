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

    # Limit boxes
    ⬜pmin = Interact.textbox(; value = 0.0, label = "pmin")
    ⬜pmax = Interact.textbox(; value = 1.0, label = "pmax")
    ⬜umin = Interact.textbox(; value = 0.0, label = "umin")
    ⬜umax = Interact.textbox(; value = 1.0, label = "umax")

    w = Window()
    s = 5em
    body!(w, Interact.vbox(
        α,
        Interact.hbox(n, Ttr, density),
        Interact.hbox(i, hskip(s), ▢update, hskip(s), ▢back, hskip(s), ▢reset),
        Interact.hline(),
        Interact.hbox(⬜pmin, ⬜pmax),
        Interact.hbox(⬜umin, ⬜umax)
        )
    )

    return n, Ttr, density, i, ▢update, ▢back, ▢reset, observe(α),
           ⬜pmin, ⬜pmax, ⬜umin, ⬜umax
end

function set_limits!(scplot, r)
    AbstractPlotting.update_limits!(scplot, r)
    AbstractPlotting.scale_scene!(scplot)
    AbstractPlotting.center!(scplot)
    AbstractPlotting.update!(scplot)
end

const varidx = Dict(1 => "₁", 2 => "₂", 3 => "₃")

function interactive_orbitdiagram(ds::DiscreteDynamicalSystem,
    i::Int, p_index, p_min, p_max;
    density = 500, u0 = get_state(ds), Ttr = 200, n = 500
    )

    # Initialization
    integ = integrator(ds)
    scene = Scene()
    pmin, pmax = p_min, p_max

    # UI elements
    n, Ttr, density, i, ▢update, ▢back, ▢reset, α, ⬜pmin, ⬜pmax, ⬜umin, ⬜umax =
    controlwindow(dimension(ds), n, Ttr, density, i)

    # Orbit diagram data
    od, xmin, xmax = minimal_normaized_od(integ, i[], p_index, pmin, pmax, density[], n[], Ttr[], u0)
    od_node = Observable(od)

    # History stores the variable index and true diagram limits
    history = [(i[], pmin, pmax, xmin, xmax)]
    ⬜pmin[] = pmin; ⬜pmax[] = pmax
    ⬜umin[] = xmin; ⬜umax[] = xmax


    color = lift(a -> RGBA(0,0,0,a), α)

    scplot = scatter(od_node, markersize = 0.01, color = color)
    scplot[Axis][:ticks][:ranges] = ([0, 1], [0, 1])
    scplot[Axis][:ticks][:labels] = (["pmin", "pmax"], ["umin", "umax"])
    scplot[Axis][:names][:axisnames] = ("p", "u"*varidx[i[]])


    display(scplot)
    rect = select_rectangle(scplot)

        on(rect) do r
        spmin, sxmin = r.origin
        spmax, sxmax = r.origin + r.widths
        # Convert p,x to true values
        j, ppmin, ppmax, pxmin, pxmax = history[end]
        pdif = ppmax - ppmin; xdif = pxmax - pxmin
        pmin = spmin*pdif + ppmin
        pmax = spmax*pdif + ppmin
        xmin = sxmin*xdif + pxmin
        xmax = sxmax*xdif + pxmin

        od_node[] = minimal_normaized_od(
            integ, j,  p_index, pmin, pmax,
            density[], n[], Ttr[], u0, xmin, xmax
        )

        push!(history, (j, pmin, pmax, xmin, xmax)) # update history
        ⬜pmin[] = pmin; ⬜pmax[] = pmax
        ⬜umin[] = xmin; ⬜umax[] = xmax
        # set_limits!(scplot, r)
    end

    # Upon selecting new variable
    on(i) do j
        println("selected var $j")

        previ, pmin, pmax, xmin, xmax = history[end]
        od, xmin, xmax = minimal_normaized_od(
            integ, j, p_index, pmin, pmax, density[], n[], Ttr[], u0
        )

        scplot[Axis][:names][:axisnames] = ("p", "u"*varidx[j])

        od_node[] = od
        ⬜pmin[] = pmin; ⬜pmax[] = pmax
        ⬜umin[] = xmin; ⬜umax[] = xmax
        push!(history, (j, pmin, pmax, xmin, xmax)) # update history
    end

    # Upon hitting the update button (just recomputes the OD)
    # TODO: Properly state limits in control
    on(▢update) do clicks
        j, pmin, pmax, xmin, xmax = history[end]
        od_node[] = minimal_normaized_od(
            integ, j, p_index, pmin, pmax, density[], n[], Ttr[], u0, xmin, xmax
        )
    end

    # TODO: Upon hitting the "reset" button
    # on(▢reset) do clicks


    display(scplot)
    return od_node
end

function minimal_normaized_od(integ, i, p_index, pmin, pmax,
                              density::Int, n::Int, Ttr::Int, u0)

    pvalues = range(pmin, stop = pmax, length = density)
    pdif = pmax - pmin
    od = Vector{Point2f0}() # make this pre-allocated
    xmin = eltype(integ.u)(Inf); xmax = eltype(integ.u)(-Inf)
    @inbounds for (j, p) in enumerate(pvalues)
        pp = (p - pmin)/pdif # p to plot, in [0, 1]
        DynamicalSystemsBase.reinit!(integ, u0)
        integ.p[p_index] = p
        DynamicalSystemsBase.step!(integ, Ttr)
        for z in 1:n
            DynamicalSystemsBase.step!(integ)
            x = integ.u[i]
            push!(od, Point2f0(pp, integ.u[i]))
            # update limits
            if x < xmin
                xmin = x
            elseif x > xmax
                xmax = x
            end
        end
    end
    # normalize x values
    xdif = xmax - xmin
    @inbounds for j in eachindex(od)
        x = od[j][2]; p = od[j][1]
        od[j] = Point2f0(p, (x - xmin)/xdif)
    end
    return od, xmin, xmax
end

function minimal_normaized_od(integ, i, p_index, pmin, pmax,
                              density::Int, n::Int, Ttr::Int, u0, xmin, xmax)

    pvalues = range(pmin, stop = pmax, length = density)
    pdif = pmax - pmin; xdif = xmax - xmin
    od = Vector{Point2f0}()
    @inbounds for p in pvalues
        pp = (p - pmin)/pdif # p to plot, in [0, 1]
        DynamicalSystemsBase.reinit!(integ, u0)
        integ.p[p_index] = p
        DynamicalSystemsBase.step!(integ, Ttr)
        for z in 1:n
            DynamicalSystemsBase.step!(integ)
            x = integ.u[i]
            if xmin ≤ x ≤ xmax
                push!(od, Point2f0(pp, (integ.u[i] - xmin)/xdif))
            end
        end
    end
    return od
end

i = 1
p_index = 1

systems = [(Systems.henon(), 0.8, 1.4), (Systems.logistic(), 3.0, 4.0),
           (Systems.standardmap(), 0.6, 1.2)]

ds, p_min, p_max = systems[2]

od_node = interactive_orbitdiagram(ds, i, p_index, p_min, p_max);

# TODO:
# add reset button that goes to the initial x0,p0
# add button to select which variable of the system is plotted
# make recomputation trigger each time one of the sliders is adjusted
