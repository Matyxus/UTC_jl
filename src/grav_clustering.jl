"""
    mutable struct GravClustering{T <: AbstractFloat}

    Structure used for GravClustering algorithms, stores all the neccessary objcets.

# Attributes
- `positions::Matrix{T}`: Nx2 matrix of positions of all points
- `weights::Vector{T}`: vector of weights of all points
- `precision::Type{T}`: given precision (Float16/32/64)
- `params::Dict`: dictionary of parameters (such as merging radius, number of iterations, etc.)

`Returns` Pair of coordinates defined as center of mass (computed by all lane shapes of Edge).
"""
mutable struct GravClustering{T <: AbstractFloat}
    positions::Matrix{T} # Matrix of positions
    weights::Vector{T} # Weights of objects
    precision::Type{T} # Precision of float numbers
    params::Dict # Params of clustering
    # Constructors
    GravClustering(size::Int64) = new{Float64}(zeros(Float64, size, 2), zeros(Float64, size), Float64, CLUSTERING_DEFAULT)
    GravClustering(size::Int64, ::Type{T}) where T <: AbstractFloat = new{T}(zeros(T, size, 2), zeros(T, size), T, CLUSTERING_DEFAULT)
    GravClustering(positions::Matrix{T}, weights::Vector{T}) where T <: AbstractFloat  = new{T}(positions, weights, T, CLUSTERING_DEFAULT)
    GravClustering(positions::Matrix{T}, weights::Vector{T}, params::V) where {T <: AbstractFloat, V <: AbstractDict}  = new{T}(positions, weights, T, params)
end

"""
    function check_params(gc::GravClustering)::Bool

    Checks parameters of GravClustering structure.

# Arguments
- `gc::GravClustering`: GravClustering structure to be checked

`Returns` True if all parameters of GravClustering are correct, False otherwise.
"""
function check_params(gc::GravClustering)::Bool
    # Check params
    for (key, type) in CLUSTERING_ATTRIBUTES
        if !haskey(gc.params, key)
            println("GravClustering is missing key: $(key) !")
            return false
        elseif type != String && !isa(gc.params[key], type)
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
    if !allunique(eachrow(gc.positions))
        println("Detected duplicates among coordinates of points!")
        return false
    end
    return true
end

"""
    function load_intervals(edge_data::String, interval::Tuple{Real, Real})::Union{Nothing, Vector{Node}}

    Loads interval nodes from the statistical XML file.

# Arguments
- `network::String`: name of road network file located in root/data/networks directory.
- `edge_data::String`: name of EdgeData file located in root/data/additional directory.
- `interval::Tuple{Real, Real}`: time interval (start, end) in second of intervals.
- `precision::Type{T}`: precision to be used (Float16/32/64).
- `params::Union{Dict, Nothing}`: parameters of GravClustering (optional)

`Returns` Nothing if an error occurs, GravClustering structure with loaded data otherwiese.
"""
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
    # Compute average values
    if length(intervals) != 1
        weights ./= length(intervals)
    end
    return GravClustering(get_centroids(graph, precision), weights, (isnothing(params) || isempty(params)) ? CLUSTERING_DEFAULT : params)
end

"""
    function load_intervals(edge_data::String, interval::Tuple{Real, Real})::Union{Nothing, Vector{Node}}

    Loads interval nodes from the statistical XML file.

# Arguments
- `edge_data::String`: name of EdgeData file located in root/data/additional directory.
- `interval::Tuple{Real, Real}`: time interval (start, end) in second of intervals.

`Returns` Nothing if an error occurs, Vector of XML Nodes otherwise.
"""
function load_intervals(edge_data::String, interval::Tuple{Real, Real})::Union{Nothing, Vector{Node}}
    println("Loading edge data from: '$(edge_data)', interval: $(interval) ...")
    edge_data_path::String = get_edge_data_path(edge_data)
    if !file_exists(edge_data_path)
        return nothing
    end
    doc::Node = xml_read(edge_data_path, Node)
    root::Node = doc[end] # doc[2], doc[1] is xml declaration
    intervals::Vector{Node} = []
    for xml_interval in children(root)
        if parse(Float64, xml_interval["end"]) > interval[2]
            break
        elseif interval[1] <= parse(Float64, xml_interval["begin"]) && interval[2] >= parse(Float64, xml_interval["end"])
            push!(intervals, xml_interval)
        end
    end
    return intervals
end
