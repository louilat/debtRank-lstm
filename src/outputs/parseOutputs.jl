"""Functions to generate outputs dataframes"""

using DataFrames

function generateMarginalEffectsOutput(∂S∂Wab::Matrix, ∂S∂Wba::Matrix, nodes_id::DataFrame)::DataFrame
    user_impact_in = sum(∂S∂Wab, 1)
    user_impact_out = sum(∂S∂Wba, 2)
    user_overall_impact = user_impact_in .+ user_impact_out
    output::DataFrame = DataFrame(id = 1:length(user_overall_impact), impact = user_overall_impact)
    output = leftjoin(output, nodes_id, on = :id)
    
    return select!(output, :node, :id, :impact)
end