using UTC_jl
using UTC_jl.BenchmarkTools


function clustering_test1()
    println("Running clustering test")
    gc::GravClustering = load_data("lust", "edgedata_lust", (25200, 32400), Float64)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    solver::BruteForce = BruteForce(gc)
    println("Running benchmark on clusterize2 function")
    return
end

function clustering_test2()
    println("Running clustering test")
    gc::GravClustering = load_data("lust", "edgedata_lust", (25200, 32400), Float64)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    # solver::BruteForce = BruteForce(gc)
    solver::Improved = Improved(gc)
    # println("Running benchmark on clusterize function")
    # clusterize(gc, solver, (gc.params["merging_radius"]^2)) 
    println("Running benchmark on clusterize2 function")
    # gc.positions = gc.positions[1:20, :]
    # clusterize2(gc, solver) 
    @btime clusterize3($gc, $solver)
    # println("Running benchmark on movements3 function")
    # @btime movements3($gc, $solver)
    # println("Running benchmark on movements4 function, num threads: $(nthreads())")
    # @btime movements4($gc, $solver)
    # println("Correct: $(all(movements(gc, solver) .== movements3(gc, solver)))")
    return
end


