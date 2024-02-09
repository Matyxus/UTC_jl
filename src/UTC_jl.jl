module UTC_jl
# Base
include("constants.jl")
include("components.jl")
include("network.jl")
# Display
include("display.jl")
# Clustering
include("grav_clustering.jl")
include("solver.jl")
include("methods/brute_force.jl")
include("methods/brute_force_cuda.jl")
include("methods/improved.jl")

# Functions
export load_data, load_network, check_params, movements, plot_network, plot_points, plot_clusters, run_clustering, get_clusters
# Structures
export GravClustering, BruteForce, BruteForceCuda, Improved 

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
    network::Network = load_network("DCC")
    gc::GravClustering = load_data("DCC", "edgedata_dcc", (25200, 32400), Float64)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    solver::Improved = Improved(gc)
    run_clustering(gc, solver; iterations=50)
    println("Max size: $(maximum(length.(get_clusters(solver))))")
    plot_clusters(network, get_clusters(solver), 30)
end



function display_test()
    network::Network = load_network("DCC")
    cluster_size = ceil(network.edges_size / 10)
    last_cluster_size = network.edges_size % 10

    clusters::Vector{Vector{Int64}} = fill([], 10)
    for cluster_index in 1:9
        for edge_index in 1:cluster_size
            push!(clusters[cluster_index], (cluster_index - 1) * cluster_size + edge_index)
        end
    end
    for edge_index in 1:last_cluster_size
        push!(clusters[10], 9 * cluster_size + edge_index)
    end

    plot_clusters(network, clusters, 0)
    # c = cgrad(:Reds)
    # r = rand(network.edges_size)
    # plot_network(network)
    # mat = 10 * rand(100, 2)
    # sizes = 20 * rand(100) .+ 3
    # plot_points(mat, sizes)
    return
end




end
