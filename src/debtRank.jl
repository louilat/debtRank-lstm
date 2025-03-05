"""Definitions of main DebtRank objects"""

using DataFrames
using Flux

include("inputs/parseInputs.jl")

struct BipartiteDebtRankLstm
    Wab::Matrix
    Wba::Matrix
end

struct DebtRankLstmSimulation
    lstm::BipartiteDebtRankLstm
    n_iter::Int
    nodes_id::DataFrame
end

function (lstm::BipartiteDebtRankLstm)(
    (ca, ha, cb, hb)::Tuple{Vector, Vector, Vector, Vector}
)::Tuple{Vector, Vector, Vector, Vector}

    pa = (1 .- ca) .* Int.(ha .> 0)
    pb = (1 .- cb) .* Int.(hb .> 0)

    next_ca = ca .+ pa
    next_cb = cb .+ pb

    next_ha = min.(1, ha + transpose(lstm.Wba) * (pb .* hb))
    next_hb = min.(1, hb + transpose(lstm.Wab) * (pa .* ha))

    return next_ca, next_ha, next_cb, next_hb
end

function BipartiteDebtRankLstm(
    impacts::DataFrame, nodes_id::DataFrame
)::BipartiteDebtRankLstm
    Wab = createWeightsMatrix(impacts, nodes_id; cluster = 1)
    Wba = createWeightsMatrix(impacts, nodes_id; cluster = 0)

    return BipartiteDebtRankLstm(Wab, Wba)
end

function DebtRankLstmSimulation(
    impacts::DataFrame, nodes_info::DataFrame, n_iter::Int
)::DebtRankLstmSimulation
    nodes_id = getNodesId(nodes_info)
    lstm = BipartiteDebtRankLstm(impacts, nodes_id)

    return DebtRankLstmSimulation(
        lstm,
        n_iter,
        nodes_id,
    )
end

function forward(
    simulation::DebtRankLstmSimulation,
    ca::Vector,
    ha::Vector,
    cb::Vector,
    hb::Vector,
    weight_a::Vector,
    weight_b::Vector,
)::Real

    for _ in 1:simulation.n_iter
        ca, ha, cb, hb = simulation.lstm((ca, ha, cb, hb))
        # println(ha)
        # println(hb)
        # println("---")
    end

    return sum(ha .* weight_a) + sum(hb .* weight_b)
end

function getMarginalEffects(
    simulation::DebtRankLstmSimulation, impacted_node::String, shock::Real
)::Tuple{Matrix, Matrix}
    impacted_node_cluster = simulation.nodes_id[
        simulation.nodes_id.node .== impacted_node, :
    ].cluster[1]
    impacted_node_id = simulation.nodes_id[
        simulation.nodes_id.node .== impacted_node, :
    ].id[1]

    nodes_id_a = simulation.nodes_id[simulation.nodes_id.cluster .== 1, :]
    nodes_id_b = simulation.nodes_id[simulation.nodes_id.cluster .== 0, :]

    na = maximum(nodes_id_a.id)
    nb = maximum(nodes_id_b.id)

    weight_a = sort!(nodes_id_a, :id).weight
    weight_b = sort!(nodes_id_b, :id).weight

    ca, ha, cb, hb = zeros(na), zeros(na), zeros(nb), zeros(nb)
    if impacted_node_cluster == 1
        ha[impacted_node_id] = shock
    else
        hb[impacted_node_id] = shock
    end

    grad = Flux.gradient(
        sim -> forward(sim, ca, ha, cb, hb, weight_a, weight_b),
        simulation,
    )
    return grad[1].lstm.Wab, grad[1].lstm.Wba
end

function fwd(
    simulation::DebtRankLstmSimulation,
    ca::Vector,
    ha::Vector,
    cb::Vector,
    hb::Vector,
    weight_a::Vector,
    weight_b::Vector,
)::Tuple{Vector, Real}
    losses_history::Vector{Vector} = []
    for _ in 1:simulation.n_iter
        ca, ha, cb, hb = simulation.lstm((ca, ha, cb, hb))
        push!(losses_history, ha)
    end

    return losses_history, sum(ha .* weight_a) + sum(hb .* weight_b)
end

function getForwardSimulation(
    simulation::DebtRankLstmSimulation, impacted_node::String, shock::Real
)::Tuple{Vector, Real}
    impacted_node_cluster = simulation.nodes_id[
        simulation.nodes_id.node .== impacted_node, :
    ].cluster[1]
    impacted_node_id = simulation.nodes_id[
        simulation.nodes_id.node .== impacted_node, :
    ].id[1]

    nodes_id_a = simulation.nodes_id[simulation.nodes_id.cluster .== 1, :]
    nodes_id_b = simulation.nodes_id[simulation.nodes_id.cluster .== 0, :]

    na = maximum(nodes_id_a.id)
    nb = maximum(nodes_id_b.id)

    weight_a = sort!(nodes_id_a, :id).weight
    weight_b = sort!(nodes_id_b, :id).weight

    ca, ha, cb, hb = zeros(na), zeros(na), zeros(nb), zeros(nb)
    if impacted_node_cluster == 1
        ha[impacted_node_id] = shock
    else
        hb[impacted_node_id] = shock
    end

    losses_history, score = fwd(simulation, ca, ha, cb, hb, weight_a, weight_b)
    return losses_history, score
end
