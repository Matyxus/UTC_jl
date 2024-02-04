module UTC_jl

# Base
include("constants.jl")
include("components.jl")
include("network.jl")
# Clustering
include("clustering.jl")
# Display
include("display.jl")

network = load_network("DCC")
plot_network(network)

end



