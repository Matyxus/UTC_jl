module UTC_jl

include("constants.jl")
include("components.jl")
include("network.jl")
include("display.jl")

network = load_network("DCC")
plot_network(network)

end



