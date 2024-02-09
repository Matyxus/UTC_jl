using UTC_jl
using UTC_jl.BenchmarkTools
using Base.Threads

# 522.591 ms (52017 allocations: 767.17 MiB)
function movements2(gc::GravClustering, ::BruteForce)::Matrix
    movements::Matrix{gc.precision} = zeros(gc.precision, size(gc.positions))
	distances::Vector{gc.precision} = zeros(gc.precision, size(gc.positions, 1))
	attraction::Vector{gc.precision} = zeros(gc.precision, size(gc.positions, 1))
    @inbounds @simd for i in axes(movements, 1)
		x, y = gc.positions[i, :]
		for (j, row) in enumerate(eachrow(gc.positions))
        	distances[j] = (row[1] - x)^2 + (row[2] - y)^2
		end
        distances[i] = 1.0
        @assert(!(gc.precision(0) in distances))
        attraction = (gc.weights ./ distances)
        movements[i, :] = round.(vec(sum(((gc.positions .- transpose(gc.positions[i, :])) .* attraction), dims=1)); digits=5)
    end
    return movements
end

# 74.675 ms (5781 allocations: 541.84 KiB)
function movements3(gc::GravClustering, ::BruteForce)::Matrix
    movements::Matrix{gc.precision} = zeros(gc.precision, size(gc.positions))
    num_points::Int32 = size(gc.positions, 1)
	diffx, diffy = gc.precision(0), gc.precision(0)
    attraction::gc.precision = gc.precision(0)
    @inbounds @simd for i in 1:num_points
		x, y = gc.positions[i, :]
        # Computation
		for j in 1:(i-1)
            diffx, diffy = (gc.positions[j, 1] - x), (gc.positions[j, 2] - y)
            attraction = gc.weights[j] / ((diffx ^ 2) + (diffy ^ 2))
            movements[i, 1] += (diffx * attraction)
            movements[i, 2] += (diffy * attraction)
		end
        # Skip computing distance between itself
        for j in (i+1):num_points
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

function movements_test()
    gc::GravClustering = load_data("lust", "edgedata_lust", (25200, 32400), Float64)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    solver::BruteForce = BruteForce(gc)
    tmp::Improved = Improved(gc)
    println("Running benchmark on movements1 function")
    @btime movements($gc, $solver) 
    println("Running benchmark on movements2 function")
    @btime movements2($gc, $solver)
    println("Running benchmark on movements3 function")
    @btime movements3($gc, $solver)
    println("Running benchmark on movements4 function, num threads")
    @btime movements($gc, $tmp)
    return
end

movements_test()
