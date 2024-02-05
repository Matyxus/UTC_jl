
struct GravClustering{T <: AbstractFloat}
    positions::Matrix{T} # Matrix of positions
    weights::Vector{T} # Weights of objects
    precision::DataType # Precision of float numbers
    params::Dict # Params of clustering
    # Constructors
    GravClustering(size::Int64) = new{Float64}(zeros(Float64, size, 2), zeros(Float64, size), Float64, CLUSTERING_DEFAULT)
    GravClustering(size::Int64, ::Type{T}) where T <: AbstractFloat = new{T}(zeros(T, size, 2), zeros(T, size), T, CLUSTERING_DEFAULT)
    GravClustering(positions::Matrix{T}, weights::Vector{T}) where T <: AbstractFloat  = new{T}(positions, weights, T, CLUSTERING_DEFAULT)
    GravClustering(positions::Matrix{T}, weights::Vector{T}, params::V) where {T <: AbstractFloat, V <: AbstractDict}  = new{T}(positions, weights, T, params)
end

function check_params(gc::GravClustering)::Bool
    # Check params
    for (key, type) in CLUSTERING_ATTRIBUTES
        if !haskey(junction, gc.params)
            println("GravClustering is missing key: $(key) !")
            return false
        elseif type != String && !isa(type, gc.params[key])
            println("Parameter: $(key) is expected to be of type: $(type), got: $(gc.params[key]) !")
            return false
        end
    end
    # Check values
    for param in ["iterations", "merging_radius", "multiplier"] 
        if gc.params[param] <= 0
            println("Parameter: $(param) bust be greater than 0, got: $(gc.params[param])")
            return false
        end
    end
    return true
end

function load_data(network::String, edge_data::String, interval::Tuple{Real, Real}, precision::Type{T}; params::Union{Dict, Nothing} = nothing)::Union{GravClustering, Nothing} where T <: AbstractFloat
    graph::Network = load_network(network)
    if isnothing(graph)
        return nothing
    end
    intervals::Union{Nothing, Vector{Node}} = load_intervals(edge_data, interval)
    if isnothing(intervals)
        return
    end
    # Prepare vector of weights, same size as edges of network
    weights::Vector{T} = zeros(precision, graph.edges_size)
    for xml_interval in intervals
        for (i, xml_edge) in enumerate(children(xml_interval))
            weights[i] += parse(precision, xml_edge["congestionIndex"])
        end
    end
    return GravClustering(get_centroids(graph, precision), weights, (isnothing(params) || isempty(params)) ? CLUSTERING_DEFAULT : params)
end


function load_intervals(edge_data::String, interval::Tuple{Real, Real})::Union{Nothing, Vector{Node}}
    println("Loading edge data from: $(edge_data), interval: $(interval) ...")
    edge_data_path::String = get_edge_data_path(edge_data)
    if !file_exists(edge_data_path)
        return nothing
    end
    doc::Node = xml_read(edge_data_path, Node)
    root::Node = doc[end] # doc[2], doc[1] is xml declaration
    intervals::Vector{Node} = []
    for xml_interval in children(root) 
        if parse(Float64, xml_interval["begin"]) > interval[2]
            break
        elseif parse(Float64, xml_interval["begin"]) >= interval[1]
            push!(intervals, xml_interval)
        end
    end
    return intervals
end

step(::GravClustering) = throw(ErrorException("Error, function 'step' for GravClustering is not implemented!"))
movements(::GravClustering) = throw(ErrorException("Error, function 'movements' for GravClustering is not implemented!"))
clusterize(::GravClustering) = throw(ErrorException("Error, function 'clusterize' for GravClustering is not implemented!"))




