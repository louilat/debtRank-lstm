
using DataFrames

include("src/inputs/parseInputs.jl")
include("src/debtRank.jl")


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

# println(simulation.nodes_id)
# println(simulation.lstm.Wab)
# println(simulation.lstm.Wba)

# impacted_node_cluster = simulation.nodes_id[
#     simulation.nodes_id.node .== impacted_node, :
# ].cluster[1]
# impacted_node_id = simulation.nodes_id[
#     simulation.nodes_id.node .== impacted_node, :
# ].id[1]

# nodes_id_a = simulation.nodes_id[simulation.nodes_id.cluster .== 1, :]
# nodes_id_b = simulation.nodes_id[simulation.nodes_id.cluster .== 0, :]

# na = maximum(nodes_id_a.id)
# nb = maximum(nodes_id_b.id)

# weight_a = sort!(nodes_id_a, :id).weight
# weight_b = sort!(nodes_id_b, :id).weight

# ca, ha, cb, hb = zeros(na), zeros(na), zeros(nb), zeros(nb)
# if impacted_node_cluster == 1
#     ha[impacted_node_id] = shock
# else
#     hb[impacted_node_id] = shock
# end


# forward(simulation, ca, ha, cb, hb, weight_a, weight_b)

getMarginalEffects(simulation, impacted_node, shock)
