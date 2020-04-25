cd(@__DIR__)
using Pkg
Pkg.activate(@__DIR__)
CI = get(ENV, "CI", nothing) == "true" || get(ENV, "GITHUB_TOKEN", nothing) !== nothing
CI && Pkg.instantiate()

using InteractiveChaos
using Documenter
using DocumenterTools: Themes

# %%
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

makedocs(
modules=[InteractiveChaos],
doctest=false,
sitename= "InteractiveChaos",
root = @__DIR__,
format = Documenter.HTML(
    prettyurls = CI,
    assets = [
        asset("https://fonts.googleapis.com/css?family=Montserrat|Source+Code+Pro&display=swap", class=:css),
        ],
    ),
pages = [
    "Introduction" => "index.md",
    "Orbit Diagram" => "od.md",
    "Poincaré Surface of Section" => "psos.md",
    "Trajectory Highlighter" => "highlight.md",
    "Interactive Billiards" => "billiards.md",
],
)

if CI
    deploydocs(
        repo = "github.com/JuliaDynamics/InteractiveChaos.jl.git",
        target = "build",
        push_preview = true
    )
end
