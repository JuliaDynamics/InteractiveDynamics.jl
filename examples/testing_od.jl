using InteractiveChaos, Makie, DynamicalSystems, MakieLayout, Observables

function observable_slider!(layout, i, j, scene, ltext, r; wl = 40, wr = nothing)
    slider = LSlider(scene, range = r)
    text_prev = LText(scene, "$ltext =", halign = :right)
    text_after = LText(scene, lift(a -> "$(string(a))", slider.value),
    halign = :left)
    layout[i, j] = hbox!(text_prev, slider, text_after)
    return slider
end
function controlwindow!(controllayout, scene, D, parname)
    # Sliders
    nslider = observable_slider!(controllayout, 1, :, scene, "n", 1000:1000:1000000)
    Tslider = observable_slider!(controllayout, 2, :, scene, "t", 1000:1000:1000000)
    dslider = observable_slider!(controllayout, 3, :, scene, "d", 100:100:10000)
    αslider = observable_slider!(controllayout, 4, :, scene, "α", 0:0.01:1)
    # Buttons (incl. variable chooser)
    ▢update = LButton(scene, label = "update")
    ▢back = LButton(scene, label = "← back")
    ▢reset = LButton(scene, label = "reset")
    imenu = LMenu(scene, options = [string(j) for j in 1:D], width = 60)
    imenu.i_selected = 1
    controllayout[5, 1] = hbox!(
        ▢update, ▢back, ▢reset,
        LText(scene, "variable:"), imenu, width = Auto(false)
    )
    # Limit boxes. Unfortunately can't be made observables yet...
    ⬜p₋, ⬜p₊, ⬜u₋, ⬜u₊ = Observable.((0.0, 1.0, 0.0, 1.0))
    tsize = 16
    text_p₋ = LText(scene, lift(o -> "$(parname)₋ = $(o)", ⬜p₋),
        halign = :left, width = Auto(false), textsize = tsize)
    text_p₊ = LText(scene, lift(o -> "$(parname)₊ = $(o)", ⬜p₊),
        halign = :left, width = Auto(false), textsize = tsize)
    text_u₋ = LText(scene, lift(o -> "u₋ = $(o)", ⬜u₋),
        halign = :left, width = Auto(false), textsize = tsize)
    text_u₊ = LText(scene, lift(o -> "u₊ = $(o)", ⬜u₊),
        halign = :left, width = Auto(false), textsize = tsize)
    controllayout[6, 1] = grid!([text_p₋ text_p₊ ; text_u₋ text_u₊])
    ⬜p₋[], ⬜p₊[], ⬜u₋[], ⬜u₊[] = rand(4)
    return nslider.value, Tslider.value, dslider.value, αslider.value,
           imenu.i_selected, ▢update.clicks, ▢back.clicks, ▢reset.clicks,
           ⬜p₋, ⬜p₊, ⬜u₋, ⬜u₊
end

scene, layout = layoutscene()
display(scene)
ax = layout[1,1] = LAxis(scene)
controllayout = layout[1, 2] = GridLayout(height = Auto(false))
colsize!(layout, 1, Relative(3/5))
display(scene)
n, Ttr, d, α, i, ▢update, ▢back, ▢reset, ⬜p₋, ⬜p₊, ⬜u₋, ⬜u₊ =
controlwindow!(controllayout, scene, 5, "p")



# scene, layout = layoutscene()
#
# ax = layout[1, 1] = LAxis(scene)
# subgl = layout[1, 2] = GridLayout(height = Auto(false))
#
# colsize!(layout, 1, Relative(2/3))
#
# for i in 1:4
#     subgl[i, 1] = hbox!(
#         LText(scene, "var ="),
#         LSlider(scene),
#         LText(scene, "12345")
#     )
# end
#
# subgl[5, 1] = hbox!([LButton(scene, label = "Button $i") for i in 1:3]..., width = Auto(false))
# subgl[6, 1] = hbox!(LText(scene, "variable:"), LMenu(scene))
# subgl[7, 1] = grid!([LText(scene, "p = 0.0", halign = :left, width = Auto(false)) for i in 1:2, j in 1:2])
#
# scene
