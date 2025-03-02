
using DataFrames
using CSV

include("src/inputs/parseInputs.jl")
include("src/debtRank.jl")
include("src/outputs/parseOutputs.jl")


# impacts = CSV.read("sample_data/impacts.csv", DataFrame)
# nodes_info = CSV.read("sample_data/nodes_info.csv", DataFrame)

impacts = DataFrame(
    source = ["A", "A", "d", "e"],
    target = ["d", "e", "B", "C"],
    impact = [1, 1, 0.2, 0.4],
)

nodes_info = DataFrame(
    node = ["d", "B", "A", "e", "C"],
    cluster = [0, 1, 1, 0, 1],
    weight = [0, 0.4, 0.2, 0, 0.4],
)

impacted_node = "A"
shock = 0.1

simulation = DebtRankLstmSimulation(impacts, nodes_info, 5)

∂S∂Wab, ∂S∂Wba = getMarginalEffects(simulation, impacted_node, shock)

output = generateMarginalEffectsOutput(∂S∂Wab, ∂S∂Wba, simulation.nodes_id)

CSV.write("user_effects.csv", output)
