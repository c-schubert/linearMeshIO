elementTypeID_NodeCount = [ 2,3,4,4,8,6,5,3,6,9,10,27,18,14,
                            1,8,20,15,13,9,10,12,15,25,21,
                            4,5,6,20,35,56 ]

elementType_TypeID = Dict([ ("L2", 1), ("Tri3", 2), ("Quad4", 3), ("Tet4", 4),
                            ("Hex8", 5), ("L3", 8), ("Tri6", 9), ("Quad9", 10),
                            ("Tet10", 11), ("Hex27", 12)])

gmsh_tag_type= Dict([("Point", 0), ("Curve", 1), ("Surface", 2), ("Volume", 3)])


struct GMSHFileInfo{T1<:Real,T2<:Int}
    version_number::T1;
    file_type::T2;
    data_size::T2;
end

struct PhysicalEntity
    type::Int
    number::Int
    name::String
end

struct PhysicalEntities
    count::Int
    entities::Union{Nothing,Array{PhysicalEntity,1}}
end

struct Point{T1<:Int, T2<:Real}
    pointTag::T1
    x::T2
    y::T2
    z::T2
    numPhysicalTags::T1
    physicalTag::Array{T1,1}
end

struct Curve{T1<:Int, T2<:Real}
    curveTag::T1
    xmin::T2
    ymin::T2
    zmin::T2
    xmax::T2
    ymax::T2
    zmax::T2
    numPhysicalTags::T1
    physicalTag::Array{T1,1}
    numBoundingPoints::T1
    pointTag::Array{T1,1}
end

struct Surface{T1<:Int, T2<:Real}
    surfaceTag::T1
    xmin::T2
    ymin::T2
    zmin::T2
    xmax::T2
    ymax::T2
    zmax::T2
    numPhysicalTags::T1
    physicalTag::Array{T1,1}
    numBoundingCurves::T1
    curveTag::Array{T1,1}
end

struct Volume{T1<:Int, T2<:Real}
    volumeTag::T1
    xmin::T2
    ymin::T2
    zmin::T2
    xmax::T2
    ymax::T2
    zmax::T2
    numPhysicalTags::T1
    physicalTag::Array{T1,1}
    numBoundingSurfaces::T1
    surfaceTag::Array{T1,1}
end

struct MeshEntities
    points::Array{Point, 1}
    curves::Array{Curve, 1}
    surfaces::Array{Surface, 1}
    volumes::Array{Volume}
end

mutable struct Nodes{T1<:Int, T2<:Real}
    num::Vector{T1}
    x::Vector{T2}
    y::Vector{T2}
    z::Vector{T2}
    noEntities::Vector{T1}
    entityTypeID::Vector{T1}
    entityTag::Vector{T1}
end

struct Element
    number::Int
    nodes::Array{Int,1}
end

struct ElementGroup
    entityTag::Int
    entityTypeID::Int
    elementTypes::Int
    count::Int
    elements::Array{Element,1}
end

struct GMSH
    info::GMSHFileInfo
    pyhysical_entities::PhysicalEntities
    mesh_entities::MeshEntities
    nodes::Nodes
    element_groups::Array{ElementGroup,1}
end
