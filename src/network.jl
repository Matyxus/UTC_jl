import XML: read as xml_read

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
        println("Successfully loaded road network: $(name)")
        return new( 
            name, length(edges), edges, 
            Dict(edge.id => edge.internal_id for edge in edges), 
            length(junctions), junctions, junction_map
        )
    end
end


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

function get_centroids(network::Network, ::Type{T})::Matrix{T} where {T <: AbstractFloat}
    positions::Matrix{T} = zeros(network.edges_size, 2)
    for edge in network.edges 
        positions[edge.internal_id, :] .= get_centroid(edge)
    end
    return positions
end

