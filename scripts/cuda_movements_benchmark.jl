using UTC_jl
using UTC_jl.CUDA
using UTC_jl.BenchmarkTools

function for_test(positions::Matrix{T}, weights::Vector{T}) where T <: AbstractFloat
    movements::Matrix{T} = zeros(size(positions))
    for i in axes(positions, 1)
        distances::Vector{T} = vec(sum((positions .- transpose(positions[i, :])) .^ 2, dims=2))
        distances[i] = one(T)
        @assert(!(zero(T) in distances))
        movements[i, :] = vec(sum((positions .- transpose(positions[i, :])) .* weights ./ distances, dims=1))
    end
    return positions .+ movements
end

function for_test(positions::CuArray, weights::CuArray, use_scalar::Bool)
    movements::CuArray = CUDA.zeros(size(positions))
    for i in axes(positions, 1)
        distances::CuArray = vec(sum((positions .- transpose(positions[i, :])) .^ 2, dims=2))
        if use_scalar
            CUDA.@allowscalar distances[i] = one(Float32)
        else
            eye = fill(false, size(distances))
            eye[i] = true
            distances[eye] .= one(Float32)
        end
        movements[i, :] = vec(sum((positions .- transpose(positions[i, :])) .* weights ./ distances, dims=1))
    end
    return positions .+ movements
end

function for_diff_test(positions::Matrix{T}, weights::Vector{T}) where T <: AbstractFloat
    movements::Matrix{T} = zeros(size(positions))
    for i in axes(positions, 1)
        diff::Matrix{T} = positions .- transpose(positions[i, :])
        distances::Vector{T} = vec(sum(diff .^ 2, dims=2))
        distances[i] = one(T)
        @assert(!(zero(T) in distances))
        movements[i, :] = vec(sum(diff .* weights ./ distances, dims=1))
    end
    return positions .+ movements
end

function for_diff_test(positions::CuArray, weights::CuArray, use_scalar::Bool)
    movements::CuArray = CUDA.zeros(size(positions))
    for i in axes(positions, 1)
        diff::CuArray = positions .- transpose(positions[i, :])
        distances::CuArray = vec(sum(diff .^ 2, dims=2))
        if use_scalar
            CUDA.@allowscalar distances[i] = one(Float32)
        else
            eye = fill(false, size(distances))
            eye[i] = true
            distances[eye] .= one(Float32)
        end
        movements[i, :] = vec(sum(diff .* weights ./ distances, dims=1))
    end
    return positions .+ movements
end

function new_axis_test(positions::Matrix{T}, weights::Vector{T}) where T <: AbstractFloat
    transpos::Matrix{T} = positions'
    diff::Array{T} = transpos .- reshape(transpos, (size(transpos, 1), 1, size(transpos, 2)))
    distances::Matrix{T} = dropdims(sum(diff .^ 2, dims=1), dims=1)
    for i in axes(positions, 1)
        distances[i, i] = one(T)
    end
    @assert(!(zero(T) in distances))
    attraction::Matrix{T} = weights ./ distances
    movements::Matrix{T} = transpose(dropdims(sum(diff .* reshape(attraction, (1, size(attraction, 1), size(attraction, 2))), dims=2), dims=2))
    return positions .+ movements
end

function new_axis_test(positions::CuArray, weights::CuArray, use_scalar::Bool)
    transpos::CuArray = positions'
    diff::CuArray = transpos .- reshape(transpos, (size(transpos, 1), 1, size(transpos, 2)))
    distances::CuArray = dropdims(sum(diff .^ 2, dims=1), dims=1)
    if use_scalar
        for i in axes(positions, 1)
            CUDA.@allowscalar distances[i, i] = one(Float32)
        end
    else
        fill_diagonal_one(distances)
    end
    attraction::CuArray = weights ./ distances
    movements::CuArray = transpose(dropdims(sum(diff .* reshape(attraction, (1, size(attraction, 1), size(attraction, 2))), dims=2), dims=2))
    return positions .+ movements
end

function fill_diagonal_one(matrix::CuArray)
    eye = fill(false, size(matrix))
    for i in axes(eye, 1)
        eye[i, i] = true
    end
    matrix[eye] .= one(Float32)
    return
end

function movements_benchmark()
    println("Running benchmark on movements function")
    gc::GravClustering = load_data("dcc", "edgedata_dcc", (0, 3600), Float32)
    gc.weights .+= 0.001
    gc.weights .*= gc.params["multiplier"]
    @assert(check_params(gc))
    positions::Matrix{Float32} = gc.positions
    weights::Vector{Float32} = gc.weights
    cu_positions::CuArray = gc.positions |> cu
    cu_weights::CuArray = gc.weights |> cu

    println("----------------------------------------")
    println("|          Classic for cycle           |")
    println("----------------------------------------")
    println("non-CUDA:")
    @btime for_test($positions, $weights)
    println("CUDA with scalar indexing:")
    @btime for_test($cu_positions, $cu_weights, true)
    println("CUDA with bool indexing:")
    @btime for_test($cu_positions, $cu_weights, false)
    println("----------------------------------------")
    println("|   Classic for cycle with diff save   |")
    println("----------------------------------------")
    println("non-CUDA:")
    @btime for_diff_test($positions, $weights)
    println("CUDA with scalar indexing:")
    @btime for_diff_test($cu_positions, $cu_weights, true)
    println("CUDA with bool indexing:")
    @btime for_diff_test($cu_positions, $cu_weights, false)
    println("----------------------------------------")
    println("|              Vectorized              |")
    println("----------------------------------------")
    println("non-CUDA:")
    @btime new_axis_test($positions, $weights)
    println("CUDA with scalar indexing:")
    @btime new_axis_test($cu_positions, $cu_weights, true)
    println("CUDA with bool indexing:")
    @btime new_axis_test($cu_positions, $cu_weights, false)
    return
end

movements_benchmark()