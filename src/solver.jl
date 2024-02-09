abstract type Solver end;

step(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'step' for Solver: $(nameof(solver)) is not implemented!"))
movements(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'movements' for Solver: $(nameof(solver)) is not implemented!"))
clusterize(::GravClustering, solver::T) where T <: Solver = throw(ErrorException("Error, function 'clusterize' for Solver: $(nameof(solver)) is not implemented!"))




