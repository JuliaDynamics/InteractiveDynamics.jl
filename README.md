![InteractiveChaos logo](https://raw.githubusercontent.com/JuliaDynamics/JuliaDynamics/master/videos/interact/interactive_chaos_logo.gif?raw=true)

Interactive applications for the exploration of chaos. Currently in beta.

[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://JuliaDynamics.github.io/InteractiveChaos.jl/dev)
[![docbuild](https://travis-ci.org/JuliaDynamics/InteractiveChaos.jl.svg?branch=master)](https://travis-ci.org/JuliaDynamics/InteractiveChaos.jl)

## Installation
You have to `add InteractiveChaos`. **Important**: `InteractiveChaos` does not install a plotting backend for you. You have to also install e.g. `Makie, GLMakie, etc.` for it to _actually_ plot!

## Usage
The package `InteractiveChaos` is hooked up to the **DynamicalSystems.jl** ecosystem, whose [documentation page](https://JuliaDynamics.github.io/DynamicalSystems.jl/dev) is independent from [`InteractiveChaos`' documentation](https://JuliaDynamics.github.io/InteractiveChaos.jl/dev).

The functionality of `InteractiveChaos` is contained in individual functions all accepting some instance of a `DynamicalSystem`. These functions upon call launch interactive applications for exploring chaotic systems. All functions have very detailed documentation strings. The applications themselves use `Makie (AbstractPlotting), Interact, Observables, Blink`.
