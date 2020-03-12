![InteractiveChaos logo](https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/interactive_chaos_logo.gif?raw=true)

`InteractiveChaos` is a package that provides applications for interactively exploring dynamical systems. It _extends_ various packages of [JuliaDynamics](https://juliadynamics.github.io/JuliaDynamics/).

To install it do `]add InteractiveChaos Makie`. `Makie` is necessary for providing a plotting backend, since `InteractiveChaos` does not install one by default.

The functionality of `InteractiveChaos` is contained within individual functions, all of which launch a dedicated interactive application. Here is their list:

* [`interactive_orbitdiagram`](@ref)
* [`interactive_poincaresos`](@ref)
* [`trajectory_highlighter`](@ref)

!!! info "Videos & Animations"
    Besides the documentation strings, each interactive function is accompanied with an animation (`.gif` or `.mp4` file) displayed after the docstring, as well as a video tutorial demonstrating its use. See the individual pages for the video links (by clicking the documentation string links)!
