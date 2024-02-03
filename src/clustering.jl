
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

function check_params(clustering::GravClustering)::Bool
    return true
end





