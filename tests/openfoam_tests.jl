include("../src/linearMeshIO.jl")

of_casefolder = joinpath(pwd(), "tests/meshes/OpenFOAM/pipe_ascii")

of_mesh = linearMeshIO.ofMeshReader.read_openfoam_mesh(of_casefolder)
