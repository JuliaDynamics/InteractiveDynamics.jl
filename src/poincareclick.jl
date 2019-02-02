export interactivepsos

"""
    interactivepsos(cds, plane, idxs, complete; kwargs...)
Open an interactive application for exploring a Poincaré surface of section (PSOS)
of the continuous dynamical system `cds`.

The `plane` can only be the `Tuple` type accepted by [`poincaresos`](@ref),
i.e. `(i, r)` for the `i`th variable crossing the value `r`. `idxs` gives the two
indices of the variables to be displayed, since the PSOS plot is always a 2D scatterplot.
I.e. `idxs = (1, 2)` will plot the 1st versus second variable of the PSOS. It follows
that `plane[1] ∉ idxs` must be true.

`complete` is a three-argument **function** that completes the new initial state
during interactive use, see below.

## Keyword Arguments
* `direction, Ttr, rootkw` : Same use as in [`poincaresos`](@ref).
* `tfinal` : A range of values for the total integration time (chosen interactively).
* `color` : A *function* of the system's initial condition, that returns a color to
  plot the new points with. A random color is chosen by default.
* `makiekwargs` : A `NamedTuple` of keyword arguments passed to `AbstractPlotting.scatter`.
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
function interactivepsos(ds::ContinuousDynamicalSystem{IIP, S, D}, plane, idxs, complete;
                         # PSOS kwargs:
                         direction = -1, Ttr::Real = 0.0,
                         tfinal = 10 .^ range(3, stop = 6, length = 100),
                         rootkw = (xrtol = 1e-6, atol = 1e-6),
                         # AbstractPlotting kwargs:
                         color = _randomcolor, resolution = (750, 750),
                         makiekwargs = (markersize = 0.005,),
                         # DiffEq kwargs:
                         diffeq...) where {IIP, S, D}

    @assert typeof(plane) <: Tuple
    @assert length(idxs) == 2
    @assert eltype(idxs) == Int
    @assert plane[1] ∉ idxs
    u0 = get_state(ds)

    # This is the internal code of poincaresos. We use the integrator directly!
    ChaosTools._check_plane(plane, D)
    integ = integrator(ds, u0; diffeq...)
    planecrossing = ChaosTools.PlaneCrossing{D}(plane, direction > 0 )
    f = (t) -> planecrossing(integ(t))
    i = SVector{2, Int}(idxs)
    data = ChaosTools._initialize_output(get_state(ds), i)

    # Integration time slider:
    ui_tf, tf = AbstractPlotting.textslider(tfinal, "tfinal", start=tfinal[1])

    # Initial Section
    ChaosTools.poincare_cross!(data, integ, f, planecrossing, tf[], Ttr, i, rootkw)
    length(data) == 0 && @warn ChaosTools.PSOS_ERROR

    # Plot the first trajectory on the section:
    ui_ms, ms = AbstractPlotting.textslider(10 .^ range(-6, stop=1, length=1000),
    "markersize", start=0.01)
    scene = Scene(resolution = (1500, 1000))
    positions_node = Node(data)
    colors = (c = color(u0); [c for i in 1:length(data)])
    colors_node = Node(colors)
    scplot = scatter(positions_node, color = colors_node, markersize = ms)

    # Interactive part:
    on(events(scplot).mousebuttons) do buttons
        if (ispressed(scplot, Mouse.left) && !ispressed(scplot, Keyboard.space) &&
            AbstractPlotting.is_mouseinside(scplot))

            pos = mouseposition(scplot)

            x, y = pos; z = plane[2] # third variable comes from plane

            newstate = try
               complete(x, y, z)
            catch err
               @error "Could not get state, got error:" exception=err
               return
            end
            @assert length(newstate) == D

            reinit!(integ, newstate)

            data = ChaosTools._initialize_output(integ.u, i)
            ChaosTools.poincare_cross!(
                data, integ, f, planecrossing, tf[], Ttr, i, rootkw
            )

            positions = positions_node[]; colors = colors_node[]
            append!(positions, data)
            append!(colors, (c = color(newstate); [c for i in 1:length(data)]))

            # Notify the signals
            positions_node[] = positions; colors_node[] = colors

            # AbstractPlotting.scatter!(scplot, data; makiekwargs..., color = color(newstate))
        end
        # display(scene)
        # return scene
    end
    AbstractPlotting.hbox(AbstractPlotting.vbox(ui_ms, ui_tf), scplot, parent=scene)
    display(scene)
    return scene
end

_randomcolor(args...) = RGBf0(rand(Float32), rand(Float32), rand(Float32))

# TODO :
# Button that prints current initial condition and its color
