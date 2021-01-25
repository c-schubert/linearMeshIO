#= 
    Mesh Types to reproduce the structure of an OpenFOAM (poly) mesh
=#

abstract type AbstractOfMesh end

struct OfPoints <: AbstractOfMesh
    no::Int64
    x::Vector{Float64}
    y::Vector{Float64}
    z::Vector{Float64}
end


struct OfFace <: AbstractOfMesh
    no_points::Int64
    point_list::Vector{Int64}
end


struct OfFaces <: AbstractOfMesh
    no::Int64 
    face_list::Vector{OfFace}
end


struct OfPatch <: AbstractOfMesh
    no_faces::Int64
    start_face::Int64
    type::String # Wall, Patch, Empty
end


mutable struct OfMeshInfo <: AbstractOfMesh
    version::Float64
    format::String
    class::String
    location::String
    casepath::String
end


struct OfMesh <: AbstractOfMesh
    info::OfMeshInfo
    points::OfPoints
    faces::OfFaces
    patches::Vector{OfPatch}
    face_owner_cell::Vector{Int64}
    face_neighbor_cell::Vector{Int64}
end
