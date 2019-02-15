export interactive_poincaresos

"""
    interactive_poincaresos(cds, plane, idxs, complete; kwargs...)
Open an interactive application for exploring a Poincaré surface of section (PSOS)
of the continuous dynamical system `cds`. Return an observable containing the
latest initial state created by `complete`, as well as its color.

The `plane` can only be the `Tuple` type accepted by [`poincaresos`](@ref),
i.e. `(i, r)` for the `i`th variable crossing the value `r`. `idxs` gives the two
indices of the variables to be displayed, since the PSOS plot is always a 2D scatterplot.
I.e. `idxs = (1, 2)` will plot the 1st versus 2nd variable of the PSOS. It follows
that `plane[1] ∉ idxs` must be true.

`complete` is a three-argument **function** that completes the new initial state
during interactive use, see below.

## Keyword Arguments
* `direction, rootkw` : Same use as in [`poincaresos`](@ref).
* `tfinal` : A 2-element tuple for the range of values for the total integration time
  (chosen interactively).
* `Ttr` : A 2-element tuple for the range of values for the transient integration time
  (chosen interactively).
* `color` : A *function* of the system's initial condition, that returns a color to
  plot the new points with. A random color is chosen by default.
* `diffeq...` : Any extra keyword arguments are passed into `init` of DiffEq.

## Interaction
The application is a standard AbstractPlotting scatterplot, which shows the PSOS of the system,
initially using the system's `u0`. Two sliders control the final evolution time and
the size of the marker points.

Upon clicking within the bounds of the scatter plot your click is transformed into
a new initial condition, which is further evolved and its PSOS is computed and then
plotted into the scatter plot.

Your click is transformed into a full `D`-dimensional initial condition through
the function `complete`. The first two arguments of the function are the positions
of the click on the PSOS. The third argument is the value of the variable the PSOS
is defined on. To be more exact, this is how the function is called:
```julia
x, y = mouseclick; z = plane[2]
newstate = complete(x, y, z)
```
The `complete` function can throw an error for ill-condition `x, y, z`.
This will be properly handled instead of breaking the application.
This `newstate` is also given to the function `color` that
gets a new color for the new points.
"""
function interactive_poincaresos(ds::ContinuousDynamicalSystem{IIP, S, D}, plane, idxs, complete;
                         # PSOS kwargs:
                         direction = -1,
                         Ttr = (0.0, 1000.0),
                         tfinal = (1000.0, 10.0^4),
                         rootkw = (xrtol = 1e-6, atol = 1e-6),
                         # AbstractPlotting kwargs:
                         color = _randomcolor, resolution = (750, 750),
                         makiekwargs = (),
                         markersizes = (-4, -1),
                         # DiffEq kwargs:
                         diffeq...) where {IIP, S, D}

    @assert typeof(plane) <: Tuple
    @assert length(idxs) == 2
    @assert eltype(idxs) == Int
    @assert plane[1] ∉ idxs
    u0 = get_state(ds)

    # This is the low-level call of poincaresos:
    ChaosTools._check_plane(plane, D)
    integ = integrator(ds, u0; diffeq...)
    planecrossing = PlaneCrossing(plane, direction > 0)
    i = SVector{2, Int}(idxs)

    # Time sliders:
    ui_tf, tf = AbstractPlotting.textslider(
        range(tfinal[1], tfinal[2], length = 1000), "tfinal", start=tfinal[1]
    )
    ui_ttr, Ttr = AbstractPlotting.textslider(
        range(Ttr[1], Ttr[2], length = 100), "Ttr", start=Ttr[1]
    )

    # Initial Section
    data = poincaresos(integ, planecrossing, tf[], Ttr[], i, rootkw)
    length(data) == 0 && error(ChaosTools.PSOS_ERROR)

    # Plot the first trajectory on the section:
    ui_ms, ms = AbstractPlotting.textslider(range(10.0^markersizes[1], 10.0^markersizes[2];
    length = 1000), "size", start=10.0^(markersizes[2]-1))
    scene = Scene(resolution = (1500, 1000))
    positions_node = Observable(data)
    colors = (c = color(u0); [c for i in 1:length(data)])
    colors_node = Observable(colors)
    scplot = scatter(positions_node, color = colors_node, markersize = ms)

    laststate = Observable((u0, color(u0)))

    # Interactive clicking on the psos:
    on(events(scplot).mousebuttons) do buttons
        if (ispressed(scplot, Mouse.left) && !ispressed(scplot, Keyboard.space) &&
            AbstractPlotting.is_mouseinside(scplot))

            pos = mouseposition(scplot)

            x, y = pos; z = plane[2] # third variable comes from plane

            newstate = try
               complete(x, y, z)
            catch err
               @error "Could not get state, got error: " exception=err
               return
            end

            reinit!(integ, newstate)

            data = poincaresos(integ, planecrossing, tf[], Ttr[], i, rootkw)

            positions = positions_node[]; colors = colors_node[]
            append!(positions, data)
            c = color(newstate)
            append!(colors, [c for i in 1:length(data)])

            # Notify the signals
            positions_node[] = positions; colors_node[] = colors

            # Update last state
            laststate[] = (newstate, c)

            # AbstractPlotting.scatter!(scplot, data; makiekwargs..., color = color(newstate))
            # display(scene)
        end
    end

    # Button to print current state:
    statebutton = AbstractPlotting.button(Theme(raw = true, camera = campixel!), "latest state")
    on(statebutton[end][:clicks]) do c
        u0, col = laststate[]
        println("Latest state: ")
        println(u0)
        println("with color: $(col)")
    end

    AbstractPlotting.hbox(AbstractPlotting.vbox(ui_ms, ui_tf, ui_ttr, statebutton), scplot, parent=scene)
    display(scene)
    return laststate
end

_randomcolor(args...) = RGBf0(rand(Float32), rand(Float32), rand(Float32))

# TODO: Better estimate of marker size and last Tfinal
