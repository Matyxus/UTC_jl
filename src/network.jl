using Graphs
using XML


function load_graph(network_name::String)::Union{SimpleDiGraph, Nothing}
    network_name = get_network_path(network_name)
    if !file_exists(network_name)
        return nothing
    end
    println("Reading network file: '$(network_name)'")

    doc = read(network_name, Node)
    root = doc[end]
    println("Num edges: $(length(findall(node -> tag(node) == "edge" && !haskey(node, "function"), children(root))))")
    return SimpleDiGraph()
end



