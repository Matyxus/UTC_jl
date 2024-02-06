abstract type Solver end;

step(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'step' for GravClustering is not implemented!"))
movements(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'movements' for GravClustering is not implemented!"))
clusterize(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'clusterize' for GravClustering is not implemented!"))




