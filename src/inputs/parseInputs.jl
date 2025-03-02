"""Functions for transforming inputs dataframes into matrices Wab and Wba"""

using DataFrames
using SparseArrays

function getNodesId(nodes_info::DataFrame)::DataFrame
    nodes_a = nodes_info[nodes_info.cluster .== 1, [:node, :weight, :cluster]]
    nodes_a.id = 1:nrow(nodes_a)

    nodes_b = nodes_info[nodes_info.cluster .== 0, [:node, :weight, :cluster]]
    nodes_b.id = 1:nrow(nodes_b)

    return vcat(nodes_a, nodes_b)
end

function createWeightsMatrix(impacts::DataFrame, nodes_id::DataFrame; cluster::Int = 1)::SparseMatrixCSC
    n = maximum(nodes_id[nodes_id.cluster .== cluster, :].id)
    p = maximum(nodes_id[nodes_id.cluster .== (1 - cluster), :].id)

    impacts_ids = leftjoin(impacts, nodes_id, on = :source => :node)
    impacts_cluster = impacts_ids[impacts_ids.cluster .== cluster, :]
    select!(impacts_cluster, :id => :source, :target, :impact)
    impacts_cluster = leftjoin(impacts_cluster, nodes_id, on = :target => :node)
    select!(impacts_cluster, :source, :id => :target, :impact)

    return sparse(impacts_cluster.source, impacts_cluster.target, impacts_cluster.impact, n, p)
end
