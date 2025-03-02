"""Functions to generate outputs dataframes"""

using DataFrames

function generateMarginalEffectsOutput(∂S∂Wab::Matrix, ∂S∂Wba::Matrix, nodes_id::DataFrame)::DataFrame
    user_impact_in = vec(sum(∂S∂Wab, dims = 1))
    user_impact_out = vec(sum(∂S∂Wba, dims = 2))
    user_overall_impact = user_impact_in .+ user_impact_out
    output::DataFrame = DataFrame(id = 1:length(user_overall_impact), impact = user_overall_impact)
    output = leftjoin(output, nodes_id[nodes_id.cluster .== 0, :], on = :id)
    
    return select!(output, :node, :id, :impact)
end