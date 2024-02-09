using UTC_jl
using UTC_jl.BenchmarkTools


function clustering_test1()
    println("Running clustering test on naive version")
    gc::GravClustering = load_data("lust", "edgedata_lust", (25200, 32400), Float64)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    solver::BruteForce = BruteForce(gc)
    @time run_clustering(gc, solver; plot_every=0)
    return
end

function clustering_test2()
    println("Running clustering test on improved version")
    gc::GravClustering = load_data("lust", "edgedata_lust", (25200, 32400), Float64)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    solver::Improved = Improved(gc)
    @time run_clustering(gc, solver; plot_every=0)
    return
end


