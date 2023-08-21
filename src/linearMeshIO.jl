module linearMeshIO


const FileFormatSymbols = Dict(
    "OpenFoam_ASCII"=> :of_ascii,
    "OpenFoam_Bin" => :of_bin,
    "OpenFoam_Gz" => :of_gz,
    "COMSOL_MPHTXT"=> :comsol_mphtxt_ascii,
    "ANSYS_MSH_ASCII"=> :ansys_msh_ascii,
    )

include("Lexer.jl")

# include("./gmsh/GMSHtypes.jl")
# include("./openfoam/ofMeshTypes.jl")
# include("./tgrid/TGridTypes.jl")
# include("./vtk/VTKtypes.jl")

# include("./gmsh/GMSHreader.jl")
# include("./openfoam/ofMeshReader.jl")
# include("./tgrid/TGridReader.jl")
# include("./vtk/VTKreader.jl")

include("./COMSOL/COMSOLmeshReader.jl")
end