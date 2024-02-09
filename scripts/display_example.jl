using UTC_jl
using UTC_jl.Plots

function display_example()
    network::Network = load_network("DCC")
    plot_network(network)
    clustering = load_data("DCC", "edgedata_dcc", (25200, 32400), Float64)
    c = cgrad(:Reds)
    plot_network(network, edge_color=c[clustering.weights], save=true)
    plot_points(clustering.positions, (clustering.weights .+ 0.001) .* clustering.params["multiplier"], save=true)
end

function clustering_test()
    network::Network = load_network("DCC")
    gc::GravClustering = load_data("DCC", "edgedata_dcc", (25200, 32400), Float64)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    solver::BruteForce = BruteForce(gc)
    run_clustering(gc, solver; iterations=50)
    println("Max size: $(maximum(length.(get_clusters(solver))))")
    plot_clusters(network, get_clusters(solver), 30, save=true)
end

# display_example()
clustering_test()
