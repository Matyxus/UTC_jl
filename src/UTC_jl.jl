module UTC_jl

# Base
include("constants.jl")
include("components.jl")
include("network.jl")
# Clustering
include("grav_clustering.jl")


clustering::GravClustering = load_data("DCC", "edgedata_dcc", (0, 3600), Float32)
@assert(check_params(clustering))

end



