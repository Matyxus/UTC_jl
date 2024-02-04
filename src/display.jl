using RecipesBase
using Plots

@recipe function plot_junctions(junctions::Vector{Junction})
    seriestype --> :scatter
    markersize --> 3
    markeralpha --> 0.5
    map(junction->junction.x, junctions), map(junction->junction.y, junctions)
end

@recipe function plot_edges(edges::Vector{Edge})
    legend --> false
    shapes::Vector{Vector{Tuple{Float64, Float64}}} = reduce(vcat, map(edge->edge.lane_shapes, edges))
    x = [getindex.(shape, 1) for shape in shapes]
    y = [getindex.(shape, 2) for shape in shapes]
    x, y
end

check_vector_size_one(str::String)::String = str
check_vector_size_one(vec::Vector{String})::Union{Vector{String}, String} = length(vec) == 1 ? vec[1] : vec

check_argument(::String, ::Int64)::Bool = false
check_argument(vec::Vector{String}, size::Int64)::Bool = length(vec) != size

function plot_network(
        network::Network; save::Bool=false, save_path::String="", plot_title::String=network.name, 
        junction_color::Union{Vector{String}, String}=JUNCTION_COLOR, 
        edge_color::Union{Vector{String}, String}=EDGE_COLOR, background::String=BACKGROUND
    )
    edge_color = check_vector_size_one(edge_color)
    junction_color = check_vector_size_one(junction_color)
    if check_argument(junction_color, network.junctions_size)
        println("Number of junction colors: $(length(junction_color)), must equal to junctions: $(network.junctions_size)")
        return
    end
    if check_argument(edge_color, network.edges_size)
        println("Number of edge colors: $(length(edge_color)), must equal to edges: $(network.edges_size)")
        return
    end
    plot = Plots.plot(network.edges, lc=edge_color, background=background, size=PLOT_SIZE, fontfamily=FONT, plot_title=plot_title)
    Plots.plot!(network.junctions, mc=junction_color)
    display(plot)
    if save
        save_path = strip(save_path)
        if !isempty(save_path) && save_path[end] != SEP
            save_path *= SEP
        end
        Plots.savefig(save_path * network.name * ".svg")
    end
    return
end
