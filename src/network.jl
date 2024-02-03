import XML: read as xml_read, Node, children, tag

struct Edge
    id::String
    internal_id::Int64
    from::String
    to::String
    length::Float64
    lane_shapes::Vector{Vector{Tuple{Float64, Float64}}}
    function Edge(edge::Node, internal_id::Int64)::Union{Nothing, Edge}
        if tag(edge) != "edge"
            println("Error, expected tag 'edge', got: $(edge)")
            return nothing
        elseif length(children(edge)) == 0 || !all(tag(lane) == "lane" for lane in children(edge))
            println("Error, expected edge to have children with tag 'lane'!")
            return nothing
        end
        # Check params of Edge
        for (key, type) in EDGE_ATTRIBUTES
            if !haskey(edge, key)
                println("Edge: $(edge) is missing key: $(key) !")
                return nothing
            elseif type != String && isnothing(tryparse(type, edge[key]))
                println("Edge: $(edge) is expected type of key: $(key) to be: $(type), got: $(edge[key]) !")
                return nothing
            end
        end
        lane_shapes::Vector{Vector{Tuple{Float64, Float64}}} = []
        # Check params of Lane's
        for lane in children(edge)
            for (key, type) in LANE_ATTRIBUTES
                if !haskey(lane, key)
                    println("Lane: $(lane) is missing key: $(key) !")
                    return nothing
                elseif type != String && isnothing(tryparse(type, lane[key]))
                    println("Lane: $(lane) is expected type of key: $(key) to be: $(type), got: $(lane[key]) !")
                    return nothing
                end
            end
            # Check shape (must be vector of x, y pairs of type Float64)
            # shape="4586.27,1204.79 4594.12,1196.77 4613.43,1177.00 4619.13,1171.54 4625.34,1165.61 4635.97,1155.47 4650.31,1141.76 4652.49,1139.60 4669.22,1122.99 4681.59,1109.67"
            shape::Vector{Tuple{Float64, Float64}} = []
            coordinates::Vector{String} = split(lane["shape"])
            if length(coordinates) <= 1
                println("Expected lane: $(lane) shape to have multiple coordinates, got: $(lane["shape"])")
                return nothing
            end
            for coordinate in coordinates 
                vals::Vector{String} = split(coordinate, ",")
                if length(vals) != 2 || any(isnothing(tryparse(Float64, coord)) for coord in vals)
                    println("Expected lane: $(lane) shape to have 2 (x, y) coordinates of type Float64, got: $(coordinate)")
                    return nothing
                end
                push!(shape, (parse(Float64, vals[1]), parse(Float64, vals[2])))
            end
            push!(lane_shapes, shape)
        end
        return new(edge["id"], internal_id, edge["from"], edge["to"], parse(Float64, children(edge)[1]["length"]), lane_shapes)
    end
end

struct Junction
    id::String
    internal_id::Int64
    x::Float64
    y::Float64
    function Junction(junction::Node, internal_id::Int64)::Union{Nothing, Junction}
        # Check XML
        if tag(junction) != "junction"
            println("Error, expected tag 'junction', got: $(junction)")
            return nothing
        end
        # Check params
        for (key, type) in JUNCTION_ATTRIBUTES
            if !haskey(junction, key)
                println("Junction: $(junction) is missing key: $(key) !")
                return nothing
            elseif type != String && isnothing(tryparse(type, junction[key]))
                println("Junction: $(junction) is expected type of key: $(key) to be: $(type), got: $(junction[key]) !")
                return nothing
            end
        end
        return new(junction["id"], internal_id, parse(Float64, junction["x"]), parse(Float64, junction["y"]))
    end
end
# ------- Utils ------- 
is_valid(component::Node, ::Type{Edge}) = tag(component) == "edge" && !is_internal(component, Edge)
is_valid(component::Node, ::Type{Junction}) = tag(component) == "junction" && !is_internal(component, Junction)
is_internal(edge::Node, ::Type{Edge})::Bool = haskey(edge, "function") 
is_internal(junction::Node, ::Type{Junction})::Bool = (haskey(junction, "type") && junction["type"] == "internal")
Base.convert(::Type{Edge}, vals::Tuple{Node, Int64}) = Edge(vals...)
Base.convert(::Type{Junction}, vals::Tuple{Node, Int64}) = Junction(vals...)

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

    function Network(name::String, junctions::Vector{Junction}, edges::Vector{Edge})
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


