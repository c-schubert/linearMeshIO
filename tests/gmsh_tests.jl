include("../src/linearMeshIO.jl")

gmsh_file = joinpath(pwd(), "tests/meshes/gmsh/t1.msh")
# gmsh_file = joinpath(pwd(), "tests/meshes/gmsh/t2.msh")
# gmsh_file = joinpath(pwd(), "tests/meshes/gmsh/t3.msh")

gmsh = linearMeshIO.GMSHreader.readGMSH(gmsh_file);
