
struct GravClustering{T <: AbstractFloat}
    positions::Matrix{T} # Matrix of positions
    weights::Vector{T} # Weights of objects
    precision::DataType # Precision of float numbers
    params::Dict # Params of clustering
    # Constructors
    GravClustering(size::Int64) = new{Float64}(zeros(Float64, size, 2), zeros(Float64, size), Float64, CLUSTERING_DEFAULT)
    GravClustering(size::Int64, ::Type{T}) where T <: AbstractFloat = new{T}(zeros(T, size, 2), zeros(T, size), T, CLUSTERING_DEFAULT)
    GravClustering(positions::Matrix{T}, weights::Vector{T}, params::Dict) where T <: AbstractFloat  = new{T}(positions, weights, T, params)
end

function check_params(gc::GravClustering)::Bool
    return true
end

function load_data(network::String, edge_data::String, precision::Type{T})::Union{GravClustering, Nothing} where T <: AbstractFloat
    graph::Network = load_network(network)
    if isnothing(graph)
        return nothing
    end
    edge_data_path::String = get_edge_data_path(edge_data)
    if !file_exists(edge_data_path)
        return false
    end

    return nothing
end

step(gc::GravClustering) = throw(ErrorException("Error, function 'step' for GravClustering is not implemented!"))
movements(gc::GravClustering) = throw(ErrorException("Error, function 'movements' for GravClustering is not implemented!"))
clusterize(gc::GravClustering) = throw(ErrorException("Error, function 'clusterize' for GravClustering is not implemented!"))




