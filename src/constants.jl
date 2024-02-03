# -------------------- File System -------------------- 
const SEP::String = Base.Filesystem.pathsep()
# -------- Directories -------- 
const DATA_DIR::String = "data"
const NETWORK_DIR::String = DATA_DIR * SEP * "networks"
const ADDITIONAL_DIR::String = DATA_DIR * SEP * "additional"
# --- Extensions --- 
const NETWORK_EXT::String = ".net.xml"
const EDGE_DATA_EXT::String = ".out.xml"
# -------------------- File functions -------------------- 
"""
    file_exists(file_path::String; messagge::Bool = true)::Bool

    Checkes whether file exists.

# Arguments
- `file_path::String`: path to file
- `messagge::Bool`: optional parameter, prints messagge about file not existing, true by default

`Returns` True if file exists, false otherwise.
"""
function file_exists(file_path::String; messagge::Bool = true)::Bool
    exists::Bool = isfile(file_path)
    if messagge && !exists
        Base.printstyled("File: '$(file_path)' does not exist!\n"; color = :red, blink = true)
        return false
    end
    return exists
end

# Functions returning full path to file (from its name) corresponding to type
get_network_path(network_name::String)::String = (NETWORK_DIR * SEP * network_name * NETWORK_EXT)
get_edge_data_path(file_name::String)::String = (ADDITIONAL_DIR * SEP * file_name * EDGE_DATA_EXT)

# -------------------- Attributes -------------------- 
const EDGE_ATTRIBUTES::Base.ImmutableDict{String, DataType} = Base.ImmutableDict("id" => String, "from" => String, "to" => String)
const LANE_ATTRIBUTES::Base.ImmutableDict{String, DataType} = Base.ImmutableDict("id" => String, "length" => Float64, "shape" => String)
const JUNCTION_ATTRIBUTES::Base.ImmutableDict{String, DataType} = Base.ImmutableDict("id" => String, "x" => Float64, "y" => Float64)
const CLUSTERING_ATTRIBUTES::Base.ImmutableDict{String, DataType} = Base.ImmutableDict("iterations" => Int64, "plot_every" => Int64, "merging_radius" => Float64)


# -------------------- Clustering -------------------- 
const CLUSTERING_DEFAULT::Base.ImmutableDict{String, <:Real} = Base.ImmutableDict("iterations" => 100, "plot_every" => 0, "merging_radius" => 15)

