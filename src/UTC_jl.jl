module UTC_jl

# Base
include("constants.jl")
include("components.jl")
include("network.jl")
# Clustering
include("grav_clustering.jl")
include("solver.jl")
include("methods/brute_force.jl")
# Display
include("display.jl")

function clustering_test()
    clustering::GravClustering = load_data("lust", "edgedata_lust", (0, 3600), Float64)
    clustering.weights .*= clustering.params["multiplier"]
    @assert(check_params(clustering))
    println(clustering.precision)
    solver::BruteForce = BruteForce(clustering)
    step(clustering, solver)
    return
end

function display_test()
    network = load_network("DCC")
    c = cgrad(:Reds)
    r = rand(network.edges_size)
    plot_network(network, edge_color=c[r])
    mat = 10 * rand(100, 2)
    sizes = 20 * rand(100) .+ 3
    plot_points(mat, sizes)
    return
end

clustering_test()

end
