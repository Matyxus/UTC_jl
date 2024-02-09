using UTC_jl
using UTC_jl.CUDA
using Test

function clustering_test()
    clustering::GravClustering = load_data("lust", "edgedata_lust", (0, 3600), Float32)
    clustering.weights .*= clustering.params["multiplier"]
    @assert(check_params(clustering))
    println(clustering.precision)
    solver::BruteForce = BruteForce(clustering)
    movements(clustering, solver)
    return clustering.positions
end

function cuda_test()
    clustering::GravClustering = load_data("lust", "edgedata_lust", (0, 3600), Float32)
    clustering.weights .*= clustering.params["multiplier"]
    @assert(check_params(clustering))
    println(clustering.precision)
    solver::BruteForceCuda = BruteForceCuda(clustering)
    movements(clustering, solver)
    return clustering.positions
end

@testset "UTC_jl.jl" begin
    if CUDA.functional()
        @test clustering_test() ≈ cuda_test()
    end
end
