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




