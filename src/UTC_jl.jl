module UTC_jl

# Base
include("constants.jl")
include("components.jl")
include("network.jl")
# Clustering
include("grav_clustering.jl")
# Display
include("display.jl")

network = load_network("DCC")

c = cgrad(:Reds)
r = rand(network.edges_size)

plot_network(network, edge_color=c[r])

mat = 10 * rand(100, 2)
sizes = 20 * rand(100) .+ 3

plot_points(mat, sizes)

end
