# Interface for all algorithsm
abstract type Solver end;

"""
    step(::GravClustering, solver::T) 

    Performs one step of clustering.

# Arguments
- `::GravClustering`: gravitational clustering structure.
- `solver::T`: algorithm that performs clustering

`Returns` Nothing
"""
step(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'step' for Solver: $(nameof(solver)) is not implemented!"))

"""
    movements(::GravClustering, solver::T)

    Performs one step of clustering.

# Arguments
- `::GravClustering`: gravitational clustering structure.
- `solver::T`: algorithm that performs clustering

`Returns` Nothing or matrix of positions (movements)
"""
movements(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'movements' for Solver: $(nameof(solver)) is not implemented!"))

"""
    clusterize(::GravClustering, solver::T)

    Performs one clustering on data.

# Arguments
- `::GravClustering`: gravitational clustering structure.
- `solver::T`: algorithm that performs clustering

`Returns` Nothing
"""
clusterize(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'clusterize' for Solver: $(nameof(solver)) is not implemented!"))

"""
    run(gc::GravClustering, solver::T; iterations::Int64=100, plot_every::Int64=5)::Nothing

    Performs an entire run of gravtiational sorting, given algorithm.

# Arguments
- `gc::GravClustering`: gravitational clustering structure.
- `solver::T`: algorithm that performs clustering
- `iterations::Int64`: total number of iterations (optional, 100 by default)
- `plot_every::Int64`: how often should points be visualized (default 5)

`Returns` Nothing or matrix of positions (movements)
"""
function run(gc::GravClustering, solver::T; iterations::Int64=100, plot_every::Int64=5)::Nothing where T <: Solver
    println("Running clustering for: $(iterations) iterations, on solver: $(nameof(solver)) !")
    if plot_every > 0
        plot_points(gc.positions, gc.weights)
    end
    for i in 1:iterations
        step(gc, solver)
        if i % plot_every == 0
            plot_points(gc.positions, gc.weights)
        end
    end
    return
end




