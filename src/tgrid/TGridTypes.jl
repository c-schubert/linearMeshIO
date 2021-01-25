xfgridsections = Dict([("xf-comment", 0), ("xf-header", 1), ("xf-dimension", 2),
("xf-node", 10), ("xf-periodic-face", 18), ("xf-cell", 12), ("xf-face", 13), ("xf-face-tree", 59),
  ("xf-cell-tree", 58), ("xf-face-parents", 61), ("xf-zone", 45)])

celltype_nodes_per_cell = Dict([(0,nothing),(1,3),(2,4),(3,4),(4,6),(5,5),(6,5)])
celltype_faces_per_cell = Dict([(0,nothing),(1,3),(2,4),(3,4),(4,8),(5,5),(6,6)])
facetype_nodes_per_face = Dict([(0,nothing),(2,2),(3,3),(4,4)])


struct NamedZone
    ID::Int
    type::String
    name::String
end

struct NodeSection
    zoneID::Int
    firstIdx::Int
    lastIdx::Int
    coords::Union{Nothing, Array{Real, 2}}
end

struct CellSection
    zoneID::Int
    firstIdx::Int
    lastIdx::Int
    type::Int
    cellType::Int
    mixedCellTypes::Union{Nothing, Array{Int, 1}}
end

struct Face
    type::Int
    nodeIDs::Array{Int,1}
    cr::Int
    cl::Int
end

struct FaceSection
    zoneID::Int
    firstIdx::Int
    lastIdx::Int
    type::Int
    faceType::Int
    FaceTypes::Union{Nothing, Array{Face, 1}}
end

# TODO: implent and test other xf-types ...

struct gridSectionStruct
    gridIDx::UInt8
    content::Union{String, Nothing}
end

struct TGrid
    header::String
    dimensions::Int
    cellSection::Array{CellSection,1}
    faceSection::Array{FaceSection,1}
    nodeSection::Array{NodeSection,1}
    zone::Array{NamedZone,1}
end