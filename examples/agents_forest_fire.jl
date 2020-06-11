using Agents, Random
using Makie
using InteractiveChaos

cd(@__DIR__)

mutable struct Tree <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    status::Bool  # true is green and false is burning
end

function forest_step!(forest)
    for node in nodes(forest, by = :random)
        nc = get_node_contents(node, forest)
        ## the cell is empty, maybe a tree grows here
        if length(nc) == 0
            rand() ≤ forest.p && add_agent!(node, forest, true)
        else
            tree = forest[nc[1]] # by definition only 1 agent per node
            if tree.status == false  # if it is has been burning, remove it.
                kill_agent!(tree, forest)
            else
                if rand() ≤ forest.f  # the tree ignites spontaneously
                    tree.status = false
                else  # if any neighbor is on fire, set this tree on fire too
                    for cell in node_neighbors(node, forest)
                        neighbors = get_node_contents(cell, forest)
                        length(neighbors) == 0 && continue
                        if any(n -> !forest.agents[n].status, neighbors)
                            tree.status = false
                            break
                        end
                    end
                end
            end
        end
    end
end

struct Oak end
struct Pine end
struct Birch end

function model_initiation(; f = 0.02, d = 0.8, p = 0.01, griddims = (50, 50), seed = 111)
    Random.seed!(seed)
    space = GridSpace(griddims, moore = true)
    properties = Dict(:f => f, :d => d, :p => p, :treetype => Oak(), :bool => true)
    forest = AgentBasedModel(Tree, space; properties = properties)

    ## create and add trees to each node with probability d,
    ## which determines the density of the forest
    for node in nodes(forest)
        if rand() ≤ forest.d
            add_agent!(node, forest, true)
        end
    end
    return forest
end

model = model_initiation()

params = Dict(
    :f => 0.02:0.001:1.0,
    :p => 0.01:0.01:2.0,
    :treetype => [Oak(), Pine(), Birch()],
    :bool => [true, false],
)

alive(model) = count(a.status for a in allagents(model))
burned(model) = count(!a.status for a in allagents(model))
mdata = [alive, burned]
mlabels = ["alive", "burned"]

ac(a) = a.status ? "#1f851a" : "#67091b"

am(a) = :rect

p1 = interactive_abm(model, dummystep, forest_step!, params;
ac = ac, as = 1, am = am, mdata = mdata, mlabels=mlabels)
