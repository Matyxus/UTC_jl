using UTC_jl
using UTC_jl.Plots

network = load_network("DCC")
plot_network(network)
clustering = load_data("DCC", "edgedata_dcc", (25200, 32400), Float64)
c = cgrad(:Reds)
plot_network(network, c[clustering.weights])
plot_points(clustering.points, (clustering.weights .+ 0.001) .* clustering.params["multiplier"])


