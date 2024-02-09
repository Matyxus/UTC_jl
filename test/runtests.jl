using UTC_jl
using UTC_jl.CUDA
using Test

function clustering_test(clustering::GravClustering)
    solver::BruteForce = BruteForce(clustering)
    movements(clustering, solver)
    return clustering.positions
end

function cuda_test(clustering::GravClustering)
    solver::BruteForceCuda = BruteForceCuda(clustering)
    movements(clustering, solver)
    return clustering.positions
end

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

@testset verbose=true "UTC_jl" begin
    @testset "CUDA" begin
        if CUDA.functional()
            clustering::GravClustering = load_data("lust", "edgedata_lust", (0, 3600), Float32)
            clustering.weights .+= 0.001
            clustering.weights .*= clustering.params["multiplier"]
            @assert(check_params(clustering))
            @test clustering_test(clustering) ≈ cuda_test(clustering)
        end
    end
    @testset "CPU" begin
        clustering::GravClustering = load_data("lust", "edgedata_lust", (25200, 32400), Float64)
        clustering.weights .+= 0.001
        clustering.weights .*= clustering.params["multiplier"]
        @assert(check_params(clustering))
        solver::BruteForce = BruteForce(clustering)
        tmp::Improved = Improved(clustering)
        @test movements(clustering, solver) ≈ movements2(clustering, solver)
        @test movements(clustering, solver) ≈ movements3(clustering, solver)
        @test movements(clustering, solver) ≈ movements(clustering, tmp)
    end
end

