struct BruteForce <: Solver
	# Initially each point is its own cluster
	clusters::Dict{Int32, Vector{Int32}}
	indexes::Vector{Int32}
	BruteForce(gc::GravClustering) = new(Dict(i => [i] for i in axes(gc.positions, 1)), [i for i in axes(gc.positions, 1)])
end


function step(gc::GravClustering, solver::BruteForce)
    println("Applying step of BruteForce on clustering!")
    movements(gc, solver)
    clustering(gc, solver, gc.params["radius"] ^ 2)
end

function movements(gc::GravClustering, ::BruteForce)::Nothing
    println("Calculating movements of clusters by BruteForce")
    # ------------------ Calculate movement of points based on grav. attraction ------------------
    movements::Matrix{gc.precision} = zeros(size(gc.positions))
    for i in axes(movements, 1)
        distances::Vector{gc.precision} = vec(sum(((gc.positions .- transpose(gc.positions[i, :])) .^ 2), dims=2))
        distances[i] = 1.0
        @assert(!(gc.precision(0) in distances))
        attraction::Vector{gc.precision} = round.((gc.weights ./ distances); digits=5)
        movements[i, :] = vec(sum(transpose((gc.positions .- transpose(gc.positions[i, :])) .* attraction), dims=2))
    end
    gc.positions .+= movements
    return
end


function clusterize(gc::GravClustering, solver::BruteForce, radius::Real)
    println("Clusterings by BruteForce, total points: $(size(gc.positions, 1))")
	# ------------------ Clustering ------------------
	index::Int32 = 0
	while index < axes(gc.positions, 1)
		println("Checking point: $(index)")
		# Check if point is still not in cluster
		@assert(haskey(solver.clusters, solver.indexes[index]))
		# Find points in merging radius relative to current point
		distances::Vector{gc.precision} = sum(((gc.positions .- transpose(gc.positions[i, :])) .^ 2), dims=2)
		distances[index] = typemax(gc.precision) # Avoid merging the same point
		points::Vector{Int32} = findall(x -> x < radius, distances)
		println("Total nearby points: $(length(points))")
		if length(points) != 0
			# Get the max weight of points which are merging
			leader_i::Int32 = argmax(gc.weights[points])
			leader_index::Int32 = points[leader_i]
			# New leader index was inside points
			if gc.weights[leader_index] > gc.weights[index]
				points = deleteat!(points, leader_i) # delete the new leader index
				push!(points, index)
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
				append!(solver.clusters[solver.indexes[leader_index]], pop!(solver.clusters[solver.indexes[point]]))
				gc.weights[leader_index] += gc.weights[point]
			end
			# Remove points from further calculation
			solver.indexes = deleteat!(solver.indexes, points)
			gc.weights = deleteat!(gc.weights, points)
			gc.positions = gc.positions[setdiff(1:end, points), :]
		end
		index += 1
	end
end




