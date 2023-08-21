abstract type AbstractCOMSOLMesh end

# Currently supported file version is 0.1

# edg	Edge element	Edge Lagrange P1
# tri	Triangular element	Triangle Lagrange P1
# quad	Quadrilateral element	Quadrilateral Lagrange P1
# tet	Tetrahedral element	Tetrahedron Lagrange P1
# prism	Prism element	Pentahedron Lagrange P1
# hex	Hexahedal element	Hexahedron Lagrange P1
# edg2	Edge element (P2)	Edge Lagrange P2
# tri2	Triangular element (P2)	Triangle Lagrange P2
# quad2	Quadrilateral element (P2*)	Quadrilateral Lagrange P2
# tet2	Tetrahedral element (P2)	Tetrahedron Lagrange P2
# hex2	Hexahedral element (P2*)	Hexahedron Lagrange P2


#= 
# FILE FORMAT:

The COMSOL Multiphysics native data file format has a global version number, so that it
is possible to revise the whole structure. The first entry in each file is the file
format, indicated by two integers. The first integer is the major file version and the
second is referred to as the minor file version. For the current version, the first two
entries in a file is 0 1. The following sections describe the file structure of the
supported version.

File Version 0.1

After the file version, the file contains three groups of data:
 
- A number of tags stored as strings, which are used so that objects can refer to each
  other.
- A number of types, which are strings that can be used in serializing the object. The
  types are currently not used by the COMSOL Multiphysics software. (also nicht relevant)
- Objects, where each object starts with the header 0 0 1, followed by a string that
  defines which type of object that follows. 



## COMSOL Objects:
- Integer->Version.
- Integer->Not used.
- Integer->type->Serialization type, 1 for Serializable. \n If type equals 1, this field
  follows:
- Serializable Object:
- Integer->TypeID String->TypeID for the subtype.. \n
- Supported Serializable Objects by now are: mesh and selection TypeIDs(4, 9)

### COMSOL MESH (Serializable COMSOL Object):
- integer->Version
- integer->Space dimension (if equal to 0 no more fields). (d)
- integer->Number of mesh vertices. (np)
- integer->Lowest mesh vertex index.
- double[d][np]->Mesh points.
- integer->Number of element types (equals the number of repeats of the following
  fields). (nt)
- string->Element type.
- integer->Number of vertices per element. (nep)
- integer->Number of elements. (ne)
- integer[ne][nep]->Matrix of point indices for each element.
- integer->Number of geometric entity values. (ndom) -> Zuweisung zu Geometrischen
  (Flächen hier nicht Relevant da über Selections ausgewählt...)
- integer[ndom]->Vector of geometric entity labels for each element. 

### COMSOL SELECTION (Serializable COMSOL Object)::
- integer->Version.
- string->Selection label. The string is encoded in UTF-8
- string->Tag of corresponding object (mesh) in file.
- integer->Dimension of selection (0: vertex; 1: edge; 2: face; 3: domain in 3D).
- integer->Number of entities.
- integer[]->The indices of the entities for the selection. The integers specify the
  0-based indices of the entities (1-based for domains). 
=#

const COMSOL_ELEMENTS_ID = Dict(
    :vtx    => 0,
    :edg    => 1,
    :tri    => 2,
    :quad   => 3,
    :tet    => 4,
    :prism  => 5,
    :hex    => 6,
    :edg2   => 7,
    :tri2   => 8,
    :quad2  => 9,
    :tet2   => 10,
    :hex2   => 11
    )

const COMSOL_ELEMENTS_ID_TO_SYMBOL  = Dict(value => key for (key, value) in TokenTypeIDs_COMSOL_mphtxt)

struct COMSOLPoints <: AbstractCOMSOLMesh
    no::Int64
    x::Vector{Float64}
    y::Vector{Float64}
    z::Vector{Float64}
end

# INFOS zu Elementen:
# https://doc.comsol.com/6.0/doc/com.comsol.help.comsol/comsol_api_mesh.45.33.html
# https://doc.comsol.com/6.0/doc/com.comsol.help.comsol/comsol_api_mesh.45.36.html#4857047
struct COMSOLElement <: AbstractCOMSOLMesh
    typeID::Int64
    nodes::Vector{Points}
end

struct COMSOLFace <: AbstractCOMSOLMesh
    no_points::Int64
    point_list::Vector{Int64}
end

struct COMSOLFaces <: AbstractCOMSOLMesh
    no::Int64 
    face_list::Vector{OfFace}
end


struct COMSOLPatch <: AbstractCOMSOLMesh
    no_faces::Int64
    start_face::Int64
    type::String # Wall, Patch, Empty
end


mutable struct COMSOLMeshInfo <: AbstractCOMSOLMesh
    version::Float64
    format::String
    class::String
    location::String
    casepath::String
end


struct COMSOLMesh <: AbstractCOMSOLMesh
    info::OfMeshInfo
    points::OfPoints
    faces::OfFaces
    patches::Vector{OfPatch}
    face_owner_cell::Vector{Int64}
    face_neighbor_cell::Vector{Int64}
end
