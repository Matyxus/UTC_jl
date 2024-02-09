module UTC_jl
# Base
include("constants.jl")
include("components.jl")
include("network.jl")
# Clustering
include("grav_clustering.jl")
include("solver.jl")
include("methods/brute_force.jl")
include("methods/brute_force_cuda.jl")
include("methods/improved.jl")
# Display
include("display.jl")
# Functions
export load_data, load_network, check_params, movements, plot_network, plot_points
# Structures
export GravClustering, BruteForce, BruteForceCuda 

function cuda_test()
    clustering::GravClustering = load_data("lust", "edgedata_lust", (0, 3600), Float32)
    clustering.weights .*= clustering.params["multiplier"]
    @assert(check_params(clustering))
    println(clustering.precision)
    solver::BruteForceCuda = BruteForceCuda(clustering)
    step(clustering, solver)
    return
end

function clustering_test()
    gc::GravClustering = load_data("lust", "edgedata_lust", (25200, 32400), Float64)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    solver::Improved = Improved(gc)
    plot_points(gc.positions, gc.weights)
    for i in 1:200 
        println("------ Iteration: $(i)/200 ------")
        step(gc, solver)
        if i % 10 == 0
            plot_points(gc.positions, gc.weights)
        end
    end
end

function display_test()
    network = load_network("DCC")
    # c = cgrad(:Reds)
    # r = rand(network.edges_size)
    plot_network(network)
    # mat = 10 * rand(100, 2)
    # sizes = 20 * rand(100) .+ 3
    # plot_points(mat, sizes)
    return
end

clustering_test()

end
