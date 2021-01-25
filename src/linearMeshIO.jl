module linearMeshIO

include("./gmsh/GMSHtypes.jl")
include("./openfoam/ofMeshTypes.jl")
include("./tgrid/TGridTypes.jl")
include("./vtk/VTKtypes.jl")

include("./gmsh/GMSHreader.jl")
include("./openfoam/ofMeshReader.jl")
include("./tgrid/TGridReader.jl")
include("./vtk/VTKreader.jl")

end