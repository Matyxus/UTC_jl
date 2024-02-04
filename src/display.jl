using RecipesBase
using Plots

@recipe function plot_junctions(junctions::Vector{Junction})
    seriestype --> :scatter
    markersize --> 3
    markeralpha --> 0.5
    map(junction->junction.x, junctions), map(junction->junction.y, junctions)
end

@recipe function plot_edges(edges::Vector{Edge}, color::Union{RGBA{Float64}, String})
    legend --> false
    linecolor --> color
    xs::Vector{Float64} = []
    ys::Vector{Float64} = []
    for edge in edges
        for shape in edge.lane_shapes
            for (x, y) in shape
                push!(xs, x)
                push!(ys, y)
            end
            push!(xs, NaN)
            push!(ys, NaN)
        end
    end
    xs, ys
end

@recipe function plot_edges(edges::Vector{Edge}, color::T) where T <: Union{Vector{RGBA{Float64}}, Vector{String}}
    legend --> false
    colors::T = []
    xs::Vector{Float64} = []
    ys::Vector{Float64} = []
    for (index, edge) in enumerate(edges)
        for shape in edge.lane_shapes
            for (x, y) in shape
                push!(xs, x)
                push!(ys, y)
                push!(colors, color[index])
            end
            push!(xs, NaN)
            push!(ys, NaN)
            push!(colors, color[index])
        end
    end
    pop!(xs)
    pop!(ys)
    pop!(colors)
    linecolor --> colors
    xs, ys
end

check_vector_size_one(non_vec::Union{RGBA{Float64}, String})::Union{RGBA{Float64}, String} = non_vec
check_vector_size_one(vec::Union{Vector{RGBA{Float64}}, Vector{String}})::Union{Vector{RGBA{Float64}}, Vector{String}, RGBA{Float64}, String} = length(vec) == 1 ? vec[1] : vec

check_argument(::Union{RGBA{Float64}, String}, ::Int64)::Bool = false
check_argument(vec::Union{Vector{RGBA{Float64}}, Vector{String}}, size::Int64)::Bool = length(vec) != size

function plot_network(
        network::Network; save::Bool=false, save_path::String="", plot_title::String=network.name, 
        junction_color::Union{Vector{String}, String}=JUNCTION_COLOR, 
        edge_color::Union{Vector{RGBA{Float64}}, Vector{String}, RGBA{Float64}, String}=EDGE_COLOR, background::String=BACKGROUND
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
    plot = Plots.plot(network.edges, edge_color, background=background, size=PLOT_SIZE, fontfamily=FONT, plot_title=plot_title)
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
