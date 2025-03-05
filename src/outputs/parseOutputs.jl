"""Functions to generate outputs dataframes"""

using DataFrames

function generateMarginalEffectsOutput(∂S∂Wab::Matrix, ∂S∂Wba::Matrix, nodes_id::DataFrame)::DataFrame
    user_impact_in = vec(sum(∂S∂Wab, dims = 1))
    user_impact_out = vec(sum(∂S∂Wba, dims = 2))
    user_overall_impact = user_impact_in .+ user_impact_out
    output::DataFrame = DataFrame(
        id = 1:length(user_overall_impact),
        impact_in = user_impact_in,
        impact_out = user_impact_out,
        impact = user_overall_impact,
    )
    output = leftjoin(output, nodes_id[nodes_id.cluster .== 0, :], on = :id)
    
    return select!(output, :node, :id, :impact)
end


function generateExistingConnectionsMarginalEffectsOutput(
    ∂S∂Wab::Matrix, ∂S∂Wba::Matrix, nodes_id::DataFrame, impacts::DataFrame
)::DataFrame
    n = nrow(impacts)
    marginal_effects::Vector{Float64} = zeros(n)
    impacts_ = leftjoin(impacts, nodes_id[:, [:node, :id, :cluster]], on = :source => :node)
    select!(impacts_, :source, :target, :impact, :id => :source_id, :cluster => :source_cluster)
    impacts_ = leftjoin(impacts_, nodes_id[:, [:node, :id, :cluster]], on = :target => :node)
    select!(impacts_, :source, :target, :impact, :source_id, :source_cluster, :id => :target_id, :cluster => :target_cluster)
    for index in 1:n
        source_id = impacts_.source_id[index]
        target_id = impacts_.target_id[index]
        source_cluster = impacts_.source_cluster[index]
        target_cluster = impacts_.target_cluster[index]
        @assert source_cluster + target_cluster == 1
        if source_cluster == 0
            marginal_effects[index] = ∂S∂Wba[source_id, target_id]
        else
            marginal_effects[index] = ∂S∂Wab[source_id, target_id]
        end
    end
    impacts_.marginal_effect = marginal_effects
    return impacts_
end