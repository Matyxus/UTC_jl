import XML: Node, children, tag

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
            # Check shape (must be vector of [x, y] pairs of type Float64)
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

function get_centroid(edge::Edge)::Tuple{Float64, Float64}
    x_sum::Float64 = 0
    y_sum::Float64 = 0
    divider::Int64 = 0
    for lane_shape in edge.lane_shapes 
        for (x, y) in lane_shape 
            x_sum += x
            y_sum += y
        end
        divider += length(lane_shape)
    end
    return (x_sum / divider), (y_sum / divider)
end

# -------- Junction -------- 

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

