using RecipesBase
using Plots

@recipe function plot_edges_recipe(edges::Vector{Edge}, color::Union{RGBA{Float64}, String})
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

@recipe function plot_edges_recipe(edges::Vector{Edge}, color::T) where T <: Union{Vector{RGBA{Float64}}, Vector{String}}
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

@recipe function plot_junctions_recipe(junctions::Vector{Junction})
    seriestype --> :scatter
    markeralpha --> 0.5
    map(junction->junction.x, junctions), map(junction->junction.y, junctions)
end

check_vector_size_one(non_vec::Union{RGBA{Float64}, String, Int64}) = non_vec
check_vector_size_one(vec::Union{Vector{RGBA{Float64}}, Vector{String}, Vector{Int64}}) = length(vec) == 1 ? vec[1] : vec

check_argument(::Union{RGBA{Float64}, String, Int64}, ::Int64)::Bool = false
check_argument(vec::Union{Vector{RGBA{Float64}}, Vector{String}, Vector{Int64}}, size::Int64)::Bool = length(vec) != size

"""
    function plot_edges(edges::Vector{Edge}, edges_size::Int64; edge_color::Union{Vector{RGBA{Float64}}, Vector{String}, RGBA{Float64}, String}=EDGE_COLOR)::Bool

    Plots given edges with some options.

# Arguments
- `edges::Vector{Edge}`: edges to be plotted, expected vector length: `n`
- `edges_size::Int64`: size of `edges`, expected value: `n`
- `edge_color::Union{Vector{RGBA{Float64}}, Vector{String}, RGBA{Float64}, String}`: colors of plotted edges, expected vector length: `n`, `optional`

`Returns` True if sizes of arguments are correct, else False
"""
function plot_edges(
        edges::Vector{Edge}, edges_size::Int64; edge_color::Union{Vector{RGBA{Float64}}, Vector{String}, RGBA{Float64}, String}=EDGE_COLOR
    )::Bool
    edge_color = check_vector_size_one(edge_color)
    if check_argument(edge_color, edges_size)
        println("Number of edge colors: $(length(edge_color)), must equal to edges: $(edges_size)")
        return false
    end
    Plots.plot!(edges, edge_color)
    return true
end

"""
    function plot_junctions(junctions::Vector{Junction}, junctions_count::Int64; junction_color::Union{Vector{String}, String}=JUNCTION_COLOR, junction_size::Union{Vector{Int64}, Int64}=JUNCTION_SIZE)::Bool

    Plots given junctions with some options.

# Arguments
- `junctions::Vector{Junction}`: junctions to be plotted, expected vector length: `n`
- `junctions_count::Int64`: size of `junctions`, expected value: `n`
- `junction_color::Union{Vector{String}, String}`: colors of plotted junctions, expected vector length: `n`, `optional`
- `junction_size::Union{Vector{Int64}, Int64}`: sizes of plotted junctions, expected vector length: `n`, `optional`

`Returns` True if sizes of arguments are correct, else False
"""
function plot_junctions(
        junctions::Vector{Junction}, junctions_count::Int64; junction_color::Union{Vector{String}, String}=JUNCTION_COLOR, 
        junction_size::Union{Vector{Int64}, Int64}=JUNCTION_SIZE
    )::Bool
    junction_color = check_vector_size_one(junction_color)
    junction_size = check_vector_size_one(junction_size)
    if check_argument(junction_color, junctions_count)
        println("Number of junction colors: $(length(junction_color)), must equal to junctions: $(junctions_count)")
        return false
    elseif check_argument(junction_size, junctions_count)
        println("Number of junction sizes: $(length(junction_size)), must equal to junctions: $(junctions_count)")
        return false
    end
    Plots.plot!(junctions, mc=junction_color, ms=junction_size)
    return true
end

"""
    function save_plot(save_path::String="", file_name::String="plot")

    Saves plot.

# Arguments
- `save_path::String`: location of saved plot, `optional`
- `file_name::String`: name of saved plot, `optional`

`Returns` Nothing
"""
function save_plot(save_path::String="", file_name::String="plot")
    save_path = strip(save_path)
    if !isempty(save_path) && save_path[end] != SEP
        save_path *= SEP
    end
    Plots.savefig(save_path * file_name * ".svg")
    return
end

"""
    function plot_network(network::Network; junction_color::Union{Vector{String}, String}=JUNCTION_COLOR, junction_size::Union{Vector{Int64}, Int64}=JUNCTION_SIZE, edge_color::Union{Vector{RGBA{Float64}}, Vector{String}, RGBA{Float64}, String}=EDGE_COLOR, save::Bool=false, save_path::String="", plot_title::String=network.name, background::String=BACKGROUND)

    Plots given network with some options.

# Arguments
- `network::Network`: network to be plotted
- `junction_color::Union{Vector{String}, String}`: colors of plotted junctions, expected vector length: `n`, `optional`
- `junction_size::Union{Vector{Int64}, Int64}`: sizes of plotted junctions, expected vector length: `n`, `optional`
- `edge_color::Union{Vector{RGBA{Float64}}, Vector{String}, RGBA{Float64}, String}`: colors of plotted edges, expected vector length: `n`, `optional`
- `save::Bool`: save plot, `optional`
- `save_path::String`: location of saved plot, `optional`
- `plot_title::String`: title of plot, `optional`
- `background::String`: background color of plot, `optional`

`Returns` Nothing
"""
function plot_network(
        network::Network; junction_color::Union{Vector{String}, String}=JUNCTION_COLOR, 
        junction_size::Union{Vector{Int64}, Int64}=JUNCTION_SIZE, 
        edge_color::Union{Vector{RGBA{Float64}}, Vector{String}, RGBA{Float64}, String}=EDGE_COLOR, 
        save::Bool=false, save_path::String="", plot_title::String=network.name, background::String=BACKGROUND
    )
    plot = Plots.plot(background=background, size=PLOT_SIZE, fontfamily=FONT, plot_title=plot_title)
    plot_edges(network.edges, network.edges_size, edge_color=edge_color)
    plot_junctions(network.junctions, network.junctions_size, junction_color=junction_color, junction_size=junction_size)
    display(plot)
    if save
        save_plot(save_path, network.name)
    end
    return
end

"""
    function plot_points(coordinates::Matrix{<: AbstractFloat}, sizes::Vector{<: Real}; color::String=JUNCTION_COLOR, save::Bool=false, save_path::String="", plot_title::String="", background::String=BACKGROUND)::Bool

    Plots given points with some options.

# Arguments
- `coordinates::Matrix{<: AbstractFloat}`: points to be plotted, expected size: `(n, 2)`
- `sizes::Vector{<: Real}`: sizes of plotted points, expected length: `n`
- `color::String`: color of plotted points, `optional`
- `save::Bool`: save plot, `optional`
- `save_path::String`: location of saved plot, `optional`
- `plot_title::String`: title of plot, `optional`
- `background::String`: background color of plot, `optional`

`Returns` True if sizes of arguments are correct, else False
"""
function plot_points(
        coordinates::Matrix{<: AbstractFloat}, sizes::Vector{<: Real}; color::String=JUNCTION_COLOR,
        save::Bool=false, save_path::String="", plot_title::String="", background::String=BACKGROUND
    )::Bool
    if size(coordinates)[1] != length(sizes) || size(coordinates)[2] != 2
        println("Size of coordinates: $(size(coordinates)), must be (n, 2), where n is length of sizes: $(length(sizes))")
        return false
    end
    plot = Plots.plot(background=background, size=PLOT_SIZE, fontfamily=FONT, plot_title=plot_title)
    Plots.scatter!(coordinates[:, 1], coordinates[:, 2], ms=(sizes ./ 25), mc=color)
    display(plot)
    if save
        save_plot(save_path)
    end
    return true
end

