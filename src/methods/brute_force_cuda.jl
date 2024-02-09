using CUDA
using BenchmarkTools

struct BruteForceCuda <: Solver
	# Initially each point is its own cluster
	clusters::Dict{Int32, Vector{Int32}}
	indexes::Vector{Int32}
	BruteForceCuda(gc::GravClustering) = new(Dict(i => [i] for i in axes(gc.positions, 1)), [i for i in axes(gc.positions, 1)])
end

function step(gc::GravClustering, solver::BruteForceCuda)
    println("Applying step of BruteForceCuda on clustering")
    movements(gc, solver)
    # clusterize(gc, solver, gc.params["merging_radius"] ^ 2)
end

function fill_diagonal_one(matrix::CuArray)
    eye = fill(false, size(matrix))
    for i in axes(eye, 1)
        eye[i, i] = true
    end
    matrix[eye] .= one(Float32)
    return
end

function movements(gc::GravClustering, ::BruteForceCuda)::Nothing
    println("Calculating movements of clusters by BruteForce")
    # ------------------ Calculate movement of points based on grav. attraction ------------------
    positions::CuArray = gc.positions |> cu
    weights::CuArray = gc.weights |> cu

    transpos::CuArray = positions'
    diff::CuArray = transpos .- reshape(transpos, (size(transpos, 1), 1, size(transpos, 2)))
    distances::CuArray = dropdims(sum(diff .^ 2, dims=1), dims=1)
    fill_diagonal_one(distances)
    attraction::CuArray = weights ./ distances
    movements::CuArray = transpose(dropdims(sum(diff .* reshape(attraction, (1, size(attraction, 1), size(attraction, 2))), dims=2), dims=2))
    gc.positions = positions .+ movements
    return
end
