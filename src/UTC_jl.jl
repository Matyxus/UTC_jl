module UTC_jl

# Base
include("constants.jl")
include("components.jl")
include("network.jl")
# Clustering
include("grav_clustering.jl")
include("solver.jl")
include("methods/brute_force.jl")
include("methods/improved.jl")
# Display
include("display.jl")
# Benchmarks
include("clustering_bech.jl")

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



# brute_test_naive()

export GravClustering, load_data, BruteForce, movements, movements2, movements3

end
