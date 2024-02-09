# -------------------------- Grid -------------------------- 
"""
    Uniform spatial paritioning structure for faster fixed-radius nearest neighbour search.

# Attributes
- `grid_size_x::Int32`: row size
- `grid_size_y::Int32`: column size
- `grid_size::Int32`: total grid size (rows * colums)
- `cells::Vector{Int32}`: vector (grid_size) mapping cell id to starting position of cell id in sorted_grid
- `grid_indexes::Vector{Tuple{Int32, Int32}}`: initial index mapping (cell_id, point_id)
- `sorted_grid::Vector{Tuple{Int32, Int32}}`: sorted index mapping (cell_id, point_id) by cell_id
"""
struct Grid
    grid_size_x::Int32
    grid_size_y::Int32
    grid_size::Int32
    cells::Vector{Int32}
    grid_indexes::Vector{Tuple{Int32, Int32}}
    sorted_grid::Vector{Tuple{Int32, Int32}}
end

"""
    construct_grid(positions::Matrix{<:AbstractFloat}, radius::Real)::Grid

    Construct uniform grid based on matrix positions and given (fixed) radius,
    the goal is to have at most 3x3 cells to check for the points that can be in radius. 

# Arguments
- `positions::Matrix{<:AbstractFloat}`: matrix of points
- `radius::Real`: radius, when points are considered 'close'

`Returns` Grid structure
"""
function construct_grid(positions::Matrix{<:AbstractFloat}, radius::Real)::Grid
    # ------- Compute bounding box of grid ------- 
    min_x, min_y, max_x, max_y = find_grid_size(positions)
    # ((Max X - Min X) * (Max Y - Min Y)) / r
    grid_size_x::Int32 = ceil(Int32, (max_x - min_x) / radius) 
    grid_size_y::Int32 = ceil(Int32, (max_y - min_y) / radius)
    grid_size::Int32 = grid_size_x * grid_size_y
    # Initialize structures
    grid::Vector{Int32} = zeros(Int32, grid_size) # grid[grid_index] = count
    grid_indexes::Vector{Tuple{Int32, Int32}} = [(Int32(0), Int32(0)) for _ in axes(positions, 1)] # (grid_index, point_index)
    sorted_grid::Vector{Tuple{Int32, Int32}} = deepcopy(grid_indexes) # (grid_index, point_index)
    # Determine grid positions of each point
    @simd for i in axes(positions, 1)
        x, y = floor(Int32, abs((positions[i, 1] - min_x) / radius)), floor(Int32, abs((positions[i, 2] - min_y) / radius))
        @assert(0 < x * grid_size_y + y + 1 <= grid_size)
        grid_indexes[i] = (x * grid_size_y + y + 1, i)
        grid[grid_indexes[i][1]] += 1 # Increase count
    end
    # Cumulative sum + indexes
    cumulative::Vector{Int32} = zeros(Int32, grid_size)
    cumulative[1] = 1
    @simd for i in 1:grid_size-1
        cumulative[i+1] += grid[i] + cumulative[i]
    end
    grid = [cumulative[i] * (grid[i] != 0) for i in 1:grid_size]
    # Sort
    @simd for i in axes(positions, 1)
        sorted_grid[cumulative[grid_indexes[i][1]]] = grid_indexes[i]
        cumulative[grid_indexes[i][1]] += 1
    end
    # Sanity check
    @assert(issorted(sorted_grid, by=x->x[1]))
    for i in 1:grid_size 
        if grid[i] != 0
            @assert(sorted_grid[grid[i]][1] == i)
        end
    end
    return Grid(grid_size_x, grid_size_y, grid_size, grid, grid_indexes, sorted_grid)
end

"""
    function is_neighbour(grid::Grid, cell_a::Integer, cell_b::Integer)::Bool

    Checks wheter cell_b is neighbour of cell_a in a given grid.

# Arguments
- `grid::Grid`: current grid structure
- `cell_a::Integer`: id of first cell (origin)
- `cell_b::Integer`: id of second cell (destination - neighbour)

`Returns` True if cell_b is neghbour to cell_a, False otherise
"""
function is_neighbour(grid::Grid, cell_a::Integer, cell_b::Integer)::Bool
    # Top and bottom + diagonals
    if cell_b <= 0 || cell_b > grid.grid_size
        return false
    # Left and right + diagonals
    elseif (cell_b % grid.grid_size_y == 0 && cell_a % grid.grid_size_y == 1) || (cell_b % grid.grid_size_y == 1 && cell_a % grid.grid_size_y == 0)
        return false
    end
    return true
end

"""
    function find_grid_size(positions::Matrix{T})::Vector{T} where {T <: AbstractFloat}

    Find minimal and maximal (x, y) coordinates in given position matrix.
    Does so in parallel.

# Arguments
- `positions::Matrix{T}`: matrix of points

`Returns` minimal and maximal (x, y) coordinates (min_x, min_y, max_x, max_y)
"""
function find_grid_size(positions::Matrix{T})::Vector{T} where {T <: AbstractFloat}
    # Min X, Min Y, Max X, Max Y
    coords::Vector{Vector{T}} = [[typemax(T), typemax(T), typemin(T), typemin(T)] for _ in 1:nthreads()]
    partition::Int32 = floor(Int32, size(positions, 1) / nthreads())
    ranges::Vector{Int32} = [i*partition + partition for i in 0:nthreads()-1]
    ranges[end] += (size(positions, 1) - ranges[end])
    @inbounds Threads.@threads for id in 1:nthreads()
        @simd for j in ((id-1)*partition + 1):ranges[id]
            # Min x
            coords[id][1] = min(coords[id][1], positions[j, 1])
            # Min y
            coords[id][2] = min(coords[id][2], positions[j, 2])
            # Max x
            coords[id][3] = max(coords[id][3], positions[j, 1])
            # Max y
            coords[id][4] = max(coords[id][4], positions[j, 2])
        end
    end
    # Find the true maximum and minimum
    for j in 2:nthreads()
        # Min x
        coords[1][1] = min(coords[1][1], coords[j][1])
        # Min y
        coords[1][2] = min(coords[1][2], coords[j][2])
        # Max x
        coords[1][3] = max(coords[1][3], coords[j][3])
        # Max y
        coords[1][4] = max(coords[1][4], coords[j][4])
    end
    return coords[1]
end

# -------------------------- Solver -------------------------- 

struct Improved <: Solver
	clusters::Vector{Int32} # Array ponting the point_id to cluster_id (all points are at first in their own clusters)
	Improved(gc::GravClustering) = new([i for i in axes(gc.positions, 1)])
end


# 18.728 ms (5818 allocations: 545.94 KiB) - 6 threads
function movements(gc::GravClustering{T}, ::Improved)::Matrix{T} where {T <: AbstractFloat}
    movements::Matrix{T} = zeros(T, size(gc.positions))
    num_points::Int32 = size(gc.positions, 1)
    @inbounds Threads.@threads for i in 1:num_points
        # Vars
        diffx, diffy = T(0), T(0)
        attraction::T = T(0)
        x, y = gc.positions[i, :]
        # Computation
		@simd for j in 1:(i-1)
            diffx, diffy = (gc.positions[j, 1] - x), (gc.positions[j, 2] - y)
            attraction = gc.weights[j] / ((diffx ^ 2) + (diffy ^ 2))
            movements[i, 1] += (diffx * attraction)
            movements[i, 2] += (diffy * attraction)
		end
        # Skip computing distance between itself
        @simd for j in (i+1):num_points
            diffx, diffy = (gc.positions[j, 1] - x), (gc.positions[j, 2] - y)
            attraction = gc.weights[j] / ((diffx ^ 2) + (diffy ^ 2))
            movements[i, 1] += (diffx * attraction)
            movements[i, 2] += (diffy * attraction)
		end
        movements[i, 1] = round(movements[i, 1]; digits=5)
        movements[i, 2] = round(movements[i, 2]; digits=5)
    end
    return movements
end

function clusterize(gc::GravClustering, solver::Improved)::Nothing
    println("Clusterings by Improved, total points: $(size(gc.positions, 1)), radius: $(gc.params["merging_radius"])")
    # ------------------ Grid ------------------
    println("Generating grid ...")
    radius::Real = gc.params["merging_radius"]
    grid::Grid = construct_grid(gc.positions, radius)
    moves::Vector{Int32} = [1, -1, grid.grid_size_y, -grid.grid_size_y, grid.grid_size_y+1, grid.grid_size_y-1, -grid.grid_size_y+1, -grid.grid_size_y-1]
    # ------------------ Clustering ------------------
    println("Starting to cluster points ...")
    eaten::BitVector = falses(size(gc.positions, 1))
    visited::BitVector = falses(size(gc.positions, 1))
    grid_index::Int32, index::Int32 = 0, 0
    x::gc.precision, y::gc.precision = gc.precision(0), gc.precision(0)
    radius ^= 2
    @inbounds for i in axes(gc.positions, 1)
        if eaten[i] || visited[i]
            continue
        end
        grid_index = grid.grid_indexes[i][1]
        # Search points which are in the same cell
        index = grid.cells[grid_index]
        @assert(grid.sorted_grid[index][1] == grid_index)
        cell_neighbours::Vector{Int32} = []
        while (index <= size(gc.positions, 1)) && grid.sorted_grid[index][1] == grid_index
            if !eaten[grid.sorted_grid[index][2]]
                push!(cell_neighbours, grid.sorted_grid[index][2])
            end
            index += 1
        end
        # Compute 8-neighbourhood
        neighbours::Vector{Int32} = []
        for shift in moves
            shift += grid_index
            if is_neighbour(grid, grid_index, shift) && grid.cells[shift] != 0
                index = grid.cells[shift]
                while (index <= size(gc.positions, 1)) && grid.sorted_grid[index][1] == shift
                    if !eaten[grid.sorted_grid[index][2]]
                        push!(neighbours, grid.sorted_grid[index][2])
                    end
                    index += 1
                end
            end
        end
        # ------------------ Point distances + merge ------------------
        for point in eachindex(cell_neighbours)
            point = cell_neighbours[point]
            if eaten[point]
                continue
            end 
            # Check points inside cell (skip already checked)
            x, y = gc.positions[point, 1], gc.positions[point, 2]
            @simd for neigh in (1+point):length(cell_neighbours) 
                neigh = cell_neighbours[neigh]
                if ((gc.positions[neigh, 1] - x)^2 + (gc.positions[neigh, 2] - y)^2) < radius
                    gc.weights[point] += gc.weights[neigh]
                    solver.clusters[neigh] = point
                    @assert(!eaten[neigh])
                    eaten[neigh] = true
                end
            end
            # Check points in 8-neighbourhood
            @simd for neigh in neighbours 
                if !eaten[neigh] && ((gc.positions[neigh, 1] - x)^2 + (gc.positions[neigh, 2] - y)^2) < radius
                    gc.weights[point] += gc.weights[neigh]
                    solver.clusters[neigh] = point
                    @assert(!eaten[neigh])
                    eaten[neigh] = true
                end
            end
            # Mark point as visited
            visited[point] = true
        end
    end
    # Reverse for indexing, delete merged points
    eaten = .!eaten
    gc.positions = gc.positions[eaten, :]
    gc.weights = gc.weights[eaten]
    println("Finished clustering, new clusters size: $(size(gc.positions, 1))")
    return
end



