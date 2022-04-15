cd(@__DIR__)
using Pkg
CI = get(ENV, "CI", nothing) == "true" || get(ENV, "GITHUB_TOKEN", nothing) !== nothing
CI && Pkg.activate(@__DIR__)
CI && Pkg.instantiate()

using InteractiveDynamics
using DynamicalSystems, DynamicalBilliards, Agents
using Documenter
using DocumenterTools: Themes
using CairoMakie

# download the themes
for file in ("juliadynamics-lightdefs.scss", "juliadynamics-darkdefs.scss", "juliadynamics-style.scss")
    download("https://raw.githubusercontent.com/JuliaDynamics/doctheme/master/$file", joinpath(@__DIR__, file))
end
# create the themes
for w in ("light", "dark")
    header = read(joinpath(@__DIR__, "juliadynamics-style.scss"), String)
    theme = read(joinpath(@__DIR__, "juliadynamics-$(w)defs.scss"), String)
    write(joinpath(@__DIR__, "juliadynamics-$(w).scss"), header*"\n"*theme)
end
# compile the themes
Themes.compile(joinpath(@__DIR__, "juliadynamics-light.scss"), joinpath(@__DIR__, "src/assets/themes/documenter-light.css"))
Themes.compile(joinpath(@__DIR__, "juliadynamics-dark.scss"), joinpath(@__DIR__, "src/assets/themes/documenter-dark.css"))

# Use literate to transform files
using Literate
indir = joinpath(@__DIR__, "src")
outdir = indir
files = (
    "agents.jl",
    "billiards.jl",
)
for file in files
    Literate.markdown(joinpath(indir, file), outdir; credit = false)
end

# %%

makedocs(
modules=[InteractiveDynamics, DynamicalSystems, DynamicalBilliards, Agents],
doctest=false,
sitename= "InteractiveDynamics",
root = @__DIR__,
format = Documenter.HTML(
    prettyurls = CI,
    assets = [
        asset("https://fonts.googleapis.com/css?family=Montserrat|Source+Code+Pro&display=swap", class=:css),
        ],
    ),
    pages = [
        "Introduction" => "index.md",
        "Dynamical Systems" => "dynamicalsystems.md",
        "Billiards" => "billiards.md",
        "Agent Based Models" => "agents.md",
        # "Trajectory Highlighter" => "highlight.md",
    ],
)

if CI
    deploydocs(
        repo = "github.com/JuliaDynamics/InteractiveDynamics.jl.git",
        target = "build",
        push_preview = true
    )
end
