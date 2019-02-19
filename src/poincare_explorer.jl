using AbstractPlotting, Observables
using StatsBase
using StatsMakie
import Colors
export poincare_explorer

const DEFAULT_α = 0.01

"""
    data_highlighter(datasets, vals; kwargs...)
Open an interactive application for highlighting specific datasets
and properties of these datasets. `datasets` is a vector of _anything_ from
**DynamicalSystems.jl** that supports `plot_dataset` (currently `Dataset`
or `Matrix`). Each dataset corresponds to a specific value from `vals`
(a `Vector{<:Real}`). The value of `vals` gives each dataset
a specific color based on a colormap.

The application is composed of two windows: the left window plots the datasets,
while the right window plots the histogram of the `vals`.

## Interaction
Clicking on a bin of the histogram plot will "highlight" all data
whose value belongs in that bin. Here highlighting actually means "hidding"
(i.e. reducing their alpha plot value) all other data besides the ones you want
to highlight. Clicking on empty space on the histogram plot will reset
highlighting.

Clicking on a plot series in the left window will highlight this series
as well as the histogram bin that contains its value. Clicking on empty
space will reset the highlighting.

## Keyword Arguments
* `nbins=50, closed=:left` : used in histogram.
* `α = 0.05` : the alpha value of the hidden data.
* `hα = 0.4` : the alpha value of the hidden histogram bins. (WIP)
* `cmap = :viridis` : the colormap used.
* `kwargs...` : Anything else is propagated to `plot_dataset(data)`.
"""
function poincare_explorer(datasets, vals;
    nbins=50, closed=:left, α = 0.05,
    cmap = :viridis, hα = 0.2, kwargs...)

    N = length(datasets)
    N == length(vals) || error("data and value must have equal length")

    # First prepare the colors of the datasets:
    colormap = to_colormap(cmap, length(datasets))
    get_color(i) = Colors.color(AbstractPlotting.interpolated_getindex(
        colormap, vals[i], extrema(vals)
    ))
    # The colors are observables; the transparency can be changed
    scatter_α = [Observable(1.0) for i in 1:N]
    colors = [lift(α -> RGBAf0(get_color(i), α), scatter_α[i]) for i ∈ 1:N]
    scatter_sc = plot_datasets(datasets, colors; kwargs...)

    # now time for the histogram:
    hist = fit(StatsBase.Histogram, vals, nbins=nbins, closed=closed)
    hist_sc, hist_α = plot_histogram(hist, cmap)

    sc = AbstractPlotting.vbox(scatter_sc, hist_sc)

    selected_plot = setup_click(scatter_sc, 1)
    hist_idx = setup_click(hist_sc, 2)

    select_series(scatter_sc, selected_plot, scatter_α, hist_α, vals, hist, α)
    select_bin(hist_idx, hist, hist_α, scatter_α, vals, closed=closed, α = α)

    return sc
end


"""
    plot_histogram(hist, cmap) -> hist_sc, hist_α
Plot a histogram where the transparency (α) of each bin can be changed
and return the scene together with the αs. The bins are colored
according to a colormap.
"""
function plot_histogram(hist::StatsBase.Histogram, cmap)
    c = to_colormap(cmap, length(hist.weights))
    hist_α = [Observable(1.) for i in c]
    bincolor(αs...) = RGBAf0.(color.(c), αs)
    colors = lift(bincolor, hist_α...)
    hist_sc = plot(hist, color=colors)
    return hist_sc, hist_α
end

"""
    change_α(series_alpha, idxs, α = DEFAULT_α)
Given a vector of `Observable`s that represent the αs for some series, change
the elements with indices given by `idxs` to the value `α`.
This can be used to hide some series by using a low α value (default).
To restore the initial color, use `α = 1`.
"""
function change_α(series_alpha, idxs, α = DEFAULT_α)
    foreach(i -> series_alpha[i][] = α, idxs)
end

"""
    get_series_idx(selected_plot, scene)
Get the index of the `selected_plot` in `scene`.
"""
function get_series_idx(selected_plot, scene)
    # TODO: There is probably a better or more efficient way of doing this.
    plot_idx = findfirst(map(p->selected_plot === p, scene.plots))
    plot_idx
end

"""
    setup_click(scene, idx=1)
Given a `scene` return a `Observable` that listens to left clicks inside the scene.
The `idx` argument is used to index the tuple `(plt, click_idx)` which gives
the selected plot and the index of the selected element in the plot.
"""
function setup_click(scene, idx=1)
    selection = Observable{Any}(0)
    on(scene.events.mousebuttons) do buttons
        if ispressed(scene, Mouse.left) && AbstractPlotting.is_mouseinside(scene)
            plt, click_idx = AbstractPlotting.mouse_selection(scene)
            selection[] = (plt, click_idx)[idx]
        end
    end
    return selection
end

"""
    bin_with_val(val, hist)
Get the index of the bin in the histogram(`hist`) that contains the given value (`val`).
"""
bin_with_val(val, hist) = searchsortedfirst(hist.edges[1], val) - 1

"""
    idxs_in_bin(i, hist, val; closed=:left)
Given the values (`val`) which are histogramed in `hist`, find all the indices
which correspond to the values in the `i`-th bin.
"""
function idxs_in_bin(i, hist, val; closed=:left)
    h = hist.edges[1]
    inbin(x) = (closed == :left) ? h[i] ≤ x < h[i+1] : h[i] < x ≤ h[i+1]
    idx = findall(inbin, val)
    return idx
end


"""
    select_series(scene, selected_plot, scatter_α, hist_α, data, hist)
Setup selection of a series in a scatter plot and the corresponding histogram.
When a point of the scatter plot is clicked, the corresponding series is
highlighted (or selected) by changing the transparency of all the other series
(and corresponding histogram bins) to a very low value.
When the click is outside, the series is deselected, that is all the αs are
set back to 1.
"""
function select_series(scene, selected_plot, scatter_α,
                       hist_α, data, hist,
                       α = DEFAULT_α
                       )
    series_idx = map(get_series_idx, selected_plot, scene)
    on(series_idx) do i
        if !isa(i, Nothing)
            scatter_α[i - 1][] = 1.0
            change_α(scatter_α, setdiff(axes(scatter_α, 1), i - 1), α)
            selected_bin = bin_with_val(data[i-1], hist)
            hist_α[selected_bin][] = 1.0
            change_α(hist_α, setdiff(axes(hist_α, 1), selected_bin), α)
        else
            change_α(scatter_α, axes(scatter_α, 1), 1.0)
            change_α(hist_α, axes(hist_α, 1), 1.0)
        end
        return nothing
    end
end

"""
    select_bin(hist_idx, hist, hist_α, scatter_α, data; closed=:left, α = DEFAULT_α)
Setup a selection of a histogram bin and the corresponding series in the
scatter plot. See also [`select_series`](@ref).
"""
function select_bin(hist_idx, hist, hist_α, scatter_α, data;
    closed=:left, α = DEFAULT_α)

    on(hist_idx) do i
        if i ≠ 0
            hist_α[i][] = 1.0
            change_α(hist_α, setdiff(axes(hist.weights, 1), i), α)
            change_α(scatter_α, idxs_in_bin(i, hist, data, closed=closed), 1.0)
            change_α(scatter_α, setdiff(
                axes(scatter_α, 1), idxs_in_bin(i, hist, data, closed=closed)
            ), α)
        else
            change_α(scatter_α, axes(scatter_α, 1), 1.0)
            change_α(hist_α, axes(hist_α, 1), 1.0)
        end
        return nothing
    end
end
