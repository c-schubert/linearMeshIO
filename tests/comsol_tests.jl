include("../src/linearMeshIO.jl")

# comsol_mphtxt_mesh = joinpath(pwd(), "tests/meshes/COMSOL/kuehlrohr_atc.mphtxt")
comsol_mphtxt_mesh = joinpath(pwd(), "tests/meshes/COMSOL/kuehlrohr_atc_coarse.mphtxt")

of_mesh = linearMeshIO.read_comsol_mphtxt(comsol_mphtxt_mesh)