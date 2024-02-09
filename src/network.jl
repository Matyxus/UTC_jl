import XML: read as xml_read

"""
    struct Edge

    Structure representing an road network (of simulator SUMO representation) extracted from the network file.

# Attributes
- `name::String`: file name of the network
- `edges_size::Int64`: total number of edges
- `edges::Vector{Edge}`: vector containg all edges
- `edge_map::Dict{String, Int64}`: mapping of edge's original id to internal
- `junctions_size::Int64`: total number of junctions
- `junctions::Vector{Edge}`: vector containg all junctions
- `junction_map::Dict{String, Int64}`: mapping of junction's original id to internal
"""
struct Network
    name::String
    # Edges
    edges_size::Int64
    edges::Vector{Edge}
    edge_map::Dict{String, Int64} # Mapping of internal id to original
    # Junctions
    junctions_size::Int64
    junctions::Vector{Junction}
    junction_map::Dict{String, Int64} # Mapping of internal id to original

    function Network(name::String, junctions::Vector{Junction}, edges::Vector{Edge})::Union{Nothing, Network}
        # Check if edges or junctins are empty
        if length(junctions) == 0 || length(edges) == 0
            println("Got empty vector of junctions or edges !")
            return nothing
        end
        # Check that all junctions referenced in edges exist
        junction_map::Dict{String, Int64} = Dict(junction.id => junction.internal_id for junction in junctions)
        for edge in edges 
            if !haskey(junction_map, edge.from)
                println("Uknown from junction: $(edge.from) in edge: $(edge.id)")
                return nothing
            elseif !haskey(junction_map, edge.to)
                println("Uknown to junction: $(edge.to) in edge: $(edge.id)")
                return nothing
            end
        end
        println("Successfully loaded road network: '$(name)'")
        return new( 
            name, length(edges), edges, 
            Dict(edge.id => edge.internal_id for edge in edges), 
            length(junctions), junctions, junction_map
        )
    end
end

"""
    function load_network(network_name::String)::Union{Network, Nothing}

    Loads road network from the statistical XML file.

# Arguments
- `network::String`: name of road network file located in root/data/networks directory.

`Returns` Nothing if an error occurs, Network structure with loaded data otherwise.
"""
function load_network(network_name::String)::Union{Network, Nothing}
    network_path::String = get_network_path(network_name)
    if !file_exists(network_path)
        return nothing
    end
    println("Reading network file: '$(network_name)'")
    doc::Node = xml_read(network_path, Node)
    root::Node = doc[end] # doc[2], doc[1] is xml declaration

    function load_component(::Type{T})::Union{Nothing, Vector{T}} where T <: Union{Edge, Junction}
        components::Vector{T} = []
        for (internal_id, component_index) in enumerate(findall(component -> is_valid(component, T), children(root)))
            component::Union{T, Nothing} = convert(T, (root[component_index], internal_id))
            if isnothing(component)
                println("Error at loading: $(root[component_index])")
                return nothing
            end
            push!(components, component)
        end
        return components
    end
    # Load components
    println("Loading junctions ...")
    junctions::Union{Vector{Junction}, Nothing} = load_component(Junction)
    if isnothing(junctions)
        return nothing
    end
    println("Loading edges ...")
    edges::Union{Vector{Edge}, Nothing} = load_component(Edge)
    if isnothing(edges)
        return nothing
    end
    return Network(network_name, junctions, edges)
end

"""
    function get_centroids(network::Network, ::Type{T})::Matrix{T} where {T <: AbstractFloat}

    Generates matrix of positions, which are centers of mass of all edges.

# Arguments
- `network::Network`: road network structure
- `::Type{T}`: precision to be used (Float16/32/64).

`Returns` Nothing if an error occurs, position matrix otherwise.
"""
function get_centroids(network::Network, ::Type{T})::Matrix{T} where {T <: AbstractFloat}
    positions::Matrix{T} = zeros(network.edges_size, 2)
    for edge in network.edges 
        positions[edge.internal_id, :] .= get_centroid(edge)
    end
    # Detect duplicates (network can be badly constructed)
    correct::Vector{Int64} = unique(i -> positions[i, :], axes(positions, 1))
    if length(correct) != size(positions, 1)
        println("Warning, detected: $(size(positions)[1] - length(correct)) duplicate coordinates, correcting ...")
        for (index, duplicate) in enumerate(duplicates(positions))
            positions[duplicate, :] .+= 0.01 * index
        end
    end
    return positions
end

"""
    function duplicates(matrix::Matrix{T})::Vector{Int64} where {T <: AbstractFloat}

    Find duplicates in the positions matrix.

# Arguments
- `matrix::Matrix{T}`: matrix of positions

`Returns` Vector of indexes, which are duplicated
"""
function duplicates(matrix::Matrix{T})::Vector{Int64} where {T <: AbstractFloat}
    uniqueset = Set{Vector{T}}()
    duplicated = Vector{Int64}()
    for row_index in axes(matrix, 1)
        if matrix[row_index, :] in uniqueset
            push!(duplicated, row_index)
        else
            push!(uniqueset, matrix[row_index, :])
        end
    end
    return duplicated
end
