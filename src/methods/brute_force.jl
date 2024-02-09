mutable struct BruteForce <: Solver
	# Initially each point is its own cluster
	clusters::Dict{Int32, Vector{Int32}}
	indexes::Vector{Int32}
	BruteForce(gc::GravClustering) = new(Dict(i => [i] for i in axes(gc.positions, 1)), [i for i in axes(gc.positions, 1)])
end


function step(gc::GravClustering, solver::BruteForce)::Nothing
    println("Applying step of BruteForce on clustering")
    # movements(gc, solver)
    # clusterize(gc, solver, gc.params["merging_radius"] ^ 2)
	return
end


function movements(gc::GravClustering, ::BruteForce)::Matrix
    movements::Matrix{gc.precision} = zeros(gc.precision, size(gc.positions))
    for i in axes(movements, 1)
        distances::Vector{gc.precision} = vec(sum(((gc.positions .- transpose(gc.positions[i, :])) .^ 2), dims=2))
        distances[i] = 1.0
        @assert(!(gc.precision(0) in distances))
        attraction::Vector{gc.precision} = gc.weights ./ distances
        movements[i, :] = round.(vec(sum(((gc.positions .- transpose(gc.positions[i, :])) .* attraction), dims=1)); digits=5)
    end
    return movements
end


function clusterize(gc::GravClustering, solver::BruteForce, radius::Real)::Nothing
    println("Clusterings by BruteForce, total points: $(size(gc.positions, 1)), radius: $(radius)")
	@assert(length(unique(solver.indexes)) == length(solver.indexes) == size(gc.positions, 1))
	@assert(issorted(solver.indexes))
	# ------------------ Clustering ------------------
	index::Int32 = 1
	while index < size(gc.positions, 1)
		# Check if point is still not in cluster
		@assert(haskey(solver.clusters, solver.indexes[index]))
		# Find points in merging radius relative to current point
		distances::Vector{gc.precision} = vec(sum(((gc.positions .- transpose(gc.positions[index, :])) .^ 2), dims=2))
		distances[index] = typemax(gc.precision) # Avoid merging the same point
		points::Vector{Int32} = findall(x -> x < radius, distances)
		if length(points) != 0
			# Get the max weight of points which are merging
			leader_i::Int32 = argmax(gc.weights[points])
			leader_index::Int32 = points[leader_i]
			# New leader index was inside points
			if gc.weights[leader_index] > gc.weights[index]
				# delete the new leader index and replace by index
				points[leader_i] = index
				index -= 1 # Shift back index, since it wil get removed
			else
				leader_index = index
			end
			# Move cluster to center of (mass) merged clusters (points)
			push!(points, leader_index)
			gc.positions[leader_index, :] = sum(gc.positions[points, :], dims=1) ./ length(points)
			pop!(points)
			# Add points to cluster (to current point - cluster leader)
			for point in points
				append!(solver.clusters[solver.indexes[leader_index]], pop!(solver.clusters, solver.indexes[point]))
				gc.weights[leader_index] += gc.weights[point]
			end
			# Remove points from further calculation
			solver.indexes = solver.indexes[setdiff(1:end, points)]
			gc.weights = gc.weights[setdiff(1:end, points)]
			gc.positions = gc.positions[setdiff(1:end, points), :]
		end
		@assert(all(!isempty(solver.clusters[i]) for i in keys(solver.clusters)))
		@assert(length(unique(solver.indexes)) == length(solver.indexes) == size(gc.positions, 1))
		@assert(issorted(solver.indexes))
		index += 1
	end
    println("Clusterers after: $(size(gc.positions, 1))")
    return
end




