module UTC_jl

# Base
include("constants.jl")
include("components.jl")
include("network.jl")
# Clustering
include("grav_clustering.jl")
include("solver.jl")
include("methods/brute_force.jl")


clustering::GravClustering = load_data("lust", "edgedata_lust", (0, 3600), Float64)
clustering.weights .*= clustering.params["multiplier"]
@assert(check_params(clustering))
println(clustering.precision)
solver::BruteForce = BruteForce(clustering)
movements(clustering, solver)

end



