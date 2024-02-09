using UTC_jl
using UTC_jl.Plots

function display_example()
    network = load_network("DCC")
    plot_network(network)
    clustering = load_data("DCC", "edgedata_dcc", (25200, 32400), Float64)
    c = cgrad(:Reds)
    plot_network(network, edge_color=c[clustering.weights], save=true)
    plot_points(clustering.positions, (clustering.weights .+ 0.001) .* clustering.params["multiplier"], save=true)
end

# display_example()
