using DynamicalSystems
using Interact, Blink, AbstractPlotting
export interactive_orbitdiagram, scaleod

"""
    controlwindow(D, n, Ttr, density, i)
Create an Electron control window for the orbit diagram interactive application.

```julia
return n, Ttr, density, i, ▢update, ▢back, ▢reset, α,
       ⬜pmin, ⬜pmax, ⬜umin, ⬜umax
```

All returned values are `Observable`s.
Their value corresponds to the one chosen in the Electron window.
Items with `▢` are buttons and with `⬜` are the boxes with limits.
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

    w = Window(Dict(:height => 400, :title => "Orbit Diagram controls"))
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

function observable_slider!(layout, i, j, scene, ltext, r; wl = 80, wr = 120)
    slider = LSlider(scene, range = r)
    text_prev = LText(scene, "$ltext =", halign = :right, width = wl)
    text_after = LText(scene, lift(a -> "$(round(a))", slider.value),
    halign = :left, width = wr)
    layout[i, j] = hbox!(text_prev, slider, text_after)
    return slider
end

function controlwindow(scene, D, i0, parname)
    controllayout = GridLayout()
    # Sliders
    nslider = observable_slider!(controllayout, :, 1, scene, "n", 1000:1000:1000000)
    Tslider = observable_slider!(controllayout, :, 2, scene, "Ttr", 1000:1000:1000000)
    dslider = observable_slider!(controllayout, :, 3, scene, "d", 100:100:10000)
    αslider = observable_slider!(controllayout, :, 4, scene, "α", 0:0.01:1)
    # Buttons (incl. variable chooser)
    ▢update = LButton(scene, label = "update", width = Auto(false))
    ▢back = LButton(scene, label = "← back", width = Auto(false))
    ▢reset = LButton(scene, label = "reset", width = Auto(false))
    imenu = LMenu(scene, options = [string(j) for j in 1:D])
    controllayout[:, 5] = hbox!(▢update, ▢back, ▢reset, LText(Scene, "variable:"), imenu)
    # Limit boxes. Unfortunately can't be made observables yet...
    ⬜p₋, ⬜p₊, ⬜u₋, ⬜u₊ = Observable.((0.0, 1.0, 0.0, 1.0))
    text_p₋ = LButton(scene, label = lift(o -> "$(parname)₋ = $(o)", ⬜p₋))
    text_p₊ = LButton(scene, label = lift(o -> "$(parname)₊ = $(o)", ⬜p₊))
    text_u₋ = LButton(scene, label = lift(o -> "u₋ = $(o)", ⬜u₋))
    text_p₊ = LButton(scene, label = lift(o -> "u₊ = $(o)", ⬜u₊))
    controllayout[:, 6] = hbox!(text_p₋, text_p₊)
    controllayout[:, 7] = hbox!(text_u₋, text_u₊)

    return nslider.value, Tslider.value, dslider.value, αslider.value,
           imenu.selection, ▢update.clicks, ▢back.clicks, ▢reset.clicks,
           ⬜p₋, ⬜p₊, ⬜u₋, ⬜u₊
end



"""
    interactive_orbitdiagram(ds::DiscreteDynamicalSystem,
        i::Int, p_index, p_min, p_max;
        u0 = get_state(ds),
        parname = "p"
    )

Open an interactive application for exploring orbit diagrams (ODs) of
discrete systems. The functionality works for _any_ discrete system.

Once initialized it opens a Makie plot window and an Electron control window.

## Interaction
By using the Electron window you are able to update all parameters of the OD
interactively (like e.g. `n` or `Ttr`). You have to press `update` after changing
these parameters. You can even decide which variable to get the OD for,
by choosing one of the variables from the wheel (again, press `update` afterwards).

In the Makie window you can interactively zoom into the OD. Click
and drag with the left mouse button to select a region in the OD. This region is then
**re-computed** at a higher resolution (i.e. we don't "just zoom").

Back in the Electron window, you can press `reset` to bring the OD in the original
state (and variable). Pressing `back` will go back through the history of your exploration
History is stored when any change happens (besides transparency).

## Accessing the data
What is plotted on the application window is a _true_ orbit diagram, not a plotting
shorthand. This means that all data are obtainable and usable directly.
Internally we always scale the orbit diagram to [0,1]² (to allow `Float64` precision
even though plotting is `Float32`-based). This however means that it is
necessary to transform the data in real scale. This is done through the function
[`scaleod`](@ref) which accepts the 5 arguments returned from the current function:
```
od, pmin, pmax, umin, umax = interactive_orbitdiagram(...)
ps, us = scaleod(od, pmin, pmax, umin, umax)
```
"""
function interactive_orbitdiagram(ds::DiscreteDynamicalSystem,
    i::Int, p_index, p_min, p_max;
    density = 1000, u0 = get_state(ds), Ttr = 200, n = 500,
    parname = "p"
    )

    # UI elements
    n, Ttr, density, i, ▢update, ▢back, ▢reset, α, ⬜pmin, ⬜pmax, ⬜umin, ⬜umax =
    controlwindow(dimension(ds), n, Ttr, density, i)

    # Initial Orbit diagram data
    integ = integrator(ds, u0)
    pmin, pmax = p_min, p_max
    odinit, xmin, xmax = minimal_normalized_od(integ, i[], p_index, pmin, pmax, density[], n[], Ttr[], u0)
    od_node = Observable(odinit)
    densityinit = density[]; ninit = n[]; Ttrinit = Ttr[]

    # History stores the variable index and true diagram limits
    history = [(i[], pmin, pmax, xmin, xmax, n[], Ttr[], density[])]
    update_controls!(history[end], i, n, Ttr, density,  ⬜pmin, ⬜pmax, ⬜umin, ⬜umax)

    color = lift(a -> AbstractPlotting.RGBAf0(0,0,0,a), α)
    scplot = Scene(resolution = (1200, 800))
    scatter!(scplot, od_node, markersize = 0.008, color = color)

    scplot[Axis][:ticks][:ranges] = (collect(0:0.25:1), collect(0:0.25:1))
    scplot[Axis][:ticks][:labels] =
    (["pmin", " ", " ", " ", "pmax"], ["umin", " ", " ", " ", "umax"])
    scplot[Axis][:names][:axisnames] = (parname, "u"*subscript(i[]))

    display(scplot)
    rect = select_rectangle(scplot)

    # Uppon interactively selecting a rectangle, with value `r` (in [0,1]²)
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

        od_node[] = minimal_normalized_od(
            integ, j,  p_index, pmin, pmax,
            density[], n[], Ttr[], u0, xmin, xmax
        )
        # update history and controls
        push!(history, (j, pmin, pmax, xmin, xmax, n[], Ttr[], density[]))
        update_controls!(history[end], i, n, Ttr, density,  ⬜pmin, ⬜pmax, ⬜umin, ⬜umax)
    end

    # Upon hitting the update button
    on(▢update) do clicks
        j, pmin, pmax, xmin, xmax, m, T, d = history[end]
        # Check if there was any change:
        if !(⬜pmin[] == pmin && ⬜pmax[] == pmax && ⬜umin[] == xmin && ⬜umax[] == xmax &&
            j == i[] && m == n[] && T == Ttr[] && d == density[])

            pmin, pmax, xmin, xmax = ⬜pmin[], ⬜pmax[], ⬜umin[], ⬜umax[]
            j, m, T, d = i[], n[], Ttr[], density[]

            od_node[] = minimal_normalized_od(
            integ, j, p_index, pmin, pmax, density[], n[], Ttr[], u0, xmin, xmax
            )
            # Update history and controls
            push!(history, (j, pmin, pmax, xmin, xmax, m, T, d))
            update_controls!(history[end], i, n, Ttr, density,  ⬜pmin, ⬜pmax, ⬜umin, ⬜umax)
            scplot[Axis][:names][:axisnames] = (parname, "u"*subscript(i[]))
        end
    end

    # Upon hitting the "reset" button
    on(▢reset) do clicks
        if length(history) > 1
            deleteat!(history, 2:length(history))
            j, pmin, pmax, xmin, xmax, m, T, d = history[end]
            od_node[] = odinit
            # Update controls/labels
            update_controls!(history[end], i, n, Ttr, density,  ⬜pmin, ⬜pmax, ⬜umin, ⬜umax)
            scplot[Axis][:names][:axisnames] = (parname, "u"*subscript(j))
        end
    end

    # Upon hitting the "back" button
    on(▢back) do clicks
        if length(history) > 1
            pop!(history)
            j, pmin, pmax, xmin, xmax, m, T, d = history[end]
            od_node[] = minimal_normalized_od(
                integ, j, p_index, pmin, pmax, d, m, T, u0, xmin, xmax
            )
            # Update limits in textboxes
            update_controls!(history[end], i, n, Ttr, density,  ⬜pmin, ⬜pmax, ⬜umin, ⬜umax)
            scplot[Axis][:names][:axisnames] = (parname, "u"*subscript(j))
        end
    end

    display(scplot)
    return od_node, ⬜pmin, ⬜pmax, ⬜umin, ⬜umax
end


"""
    minimal_normalized_od(integ, i, p_index, pmin, pmax,
                         density, n, Ttr, u0)
    minimal_normalized_od(integ, i, p_index, pmin, pmax,
                         density, n, Ttr, u0, xmin, xmax)

Compute and return a minimal and normalized orbit diagram (OD).

All points are stored in a single vector of `Point2f0` to ensure fastest possible
plotting. In addition all numbers are scaled to [0, 1]. This allows us to have
64-bit precision while display is only 32-bit!

The version with `xmin, xmax` only keeps points with limits between the
real `xmin, xmax` (in the normal units of the dynamical system).
"""
function minimal_normalized_od(integ, i, p_index, pmin, pmax,
                              density::Int, n::Int, Ttr::Int, u0)

    pvalues = range(pmin, stop = pmax, length = density)
    pdif = pmax - pmin
    od = Vector{Point2f0}() # make this pre-allocated
    xmin = eltype(integ.u)(Inf); xmax = eltype(integ.u)(-Inf)
    #= @inbounds =# for (j, p) in enumerate(pvalues)
        pp = (p - pmin)/pdif # p to plot, in [0, 1]
        DynamicalSystems.reinit!(integ, u0)
        integ.p[p_index] = p
        DynamicalSystems.step!(integ, Ttr)
        for z in 1:n
            DynamicalSystems.step!(integ)
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
    # normalize x values to [0, 1]
    xdif = xmax - xmin
    #= @inbounds =# for j in eachindex(od)
        x = od[j][2]; p = od[j][1]
        od[j] = Point2f0(p, (x - xmin)/xdif)
    end
    return od, xmin, xmax
end

function minimal_normalized_od(integ, i, p_index, pmin, pmax,
                              density::Int, n::Int, Ttr::Int, u0, xmin, xmax)

    pvalues = range(pmin, stop = pmax, length = density)
    pdif = pmax - pmin; xdif = xmax - xmin
    od = Vector{Point2f0}()
    #= @inbounds =# for p in pvalues
        pp = (p - pmin)/pdif # p to plot, in [0, 1]
        DynamicalSystems.reinit!(integ, u0)
        integ.p[p_index] = p
        DynamicalSystems.step!(integ, Ttr)
        for z in 1:n
            DynamicalSystems.step!(integ)
            x = integ.u[i]
            if xmin ≤ x ≤ xmax
                push!(od, Point2f0(pp, (integ.u[i] - xmin)/xdif))
            end
        end
    end
    return od
end

function  update_controls!(h, i, n, Ttr, density, ⬜pmin, ⬜pmax, ⬜umin, ⬜umax)
    j, pmin, pmax, xmin, xmax, m, T, d = h
    i[] = j; n[] = m; Ttr[] = T; density[] = d
    ⬜pmin[] = pmin; ⬜pmax[] = pmax
    ⬜umin[] = xmin; ⬜umax[] = xmax
    return
end

"""
    scaleod(od, pmin, pmax, umin, umax) -> ps, us
Given the return values of [`interactive_orbitdiagram`](@ref), produce
orbit diagram data scaled correctly in data units. Return the data as a vector of
parameter values and a vector of corresponding variable values.
"""
function scaleod(od, pmin, pmax, umin, umax)
    oddata = od[]; L = length(oddata);
    T = promote_type(typeof(umin[]), Float32)
    ps = zeros(T, L); us = copy(ps)
    udif = umax[] - umin[]; um = umin[]
    pdif = pmax[] - pmin[]; pm = pmin[]
    @inbounds for i ∈ 1:length(oddata)
        p, u = oddata[i]
        ps[i] = pm + pdif*p; us[i] = um + udif*u
    end
    return ps, us
end

# TODO: Use `α` directly after Simon's fix, no need for observe(α)
# TODO: Add exit button that closes both windows
# TODO: Make marker GLMakie.FastPixel()
# TODO: Allow initial state to be a function of paramter (define function `get_u(f, p)`)
