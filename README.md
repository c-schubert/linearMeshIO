# LinearMeshIO

Julia library for reading different Mesh file format of meshes and parse them
to a generic (CFD - finite volume) mesh format.

**This library is currently in development and not ready for production usage by now**

## Current working state
Parsing of the following file formats to a (by file format) specific structure (see `./src/...types.jl`) should more or less work.

  - Fluent mesh file - TGrid format in ascii (*.msh) 
  - GMSH (v4.0 und v4.1)
  - OpenFOAM (ascii)

_Conversion to a more general CFD mesh structure is planed, but not ready jet_

## Usage

1. Switch to package linearMeshIO folder
2. Then, use:

``` julia
include("./src/linearMeshIO.jl")
```
3. Proceed to file format you want to read ...


### GMSH
``` julia
gmsh_file = "/path/to/file"
gmsh = linearMeshIO.GMSHreader.readGMSH(gmsh_file);
```

### TGrid
``` julia
tgrid_file= "/path/to/file"
tgrid = linearMeshIO.TGridReader.TgridMeshImport(tgrid_file)
```

### OpenFOAM

``` julia
# case folder = folder containing: 0, constant and system folders
of_casefolder = "/path/to/case/folder"
of_mesh = linearMeshIO.ofMeshReader.read_openfoam_mesh(of_casefolder)
```

## TODOs
  - build a real module structure ...
  - build some examples
  - build (more) tests meshes and automate the test functions
  - implement binary and gz support for OpenFOAM files
  - implement VTK mesh file support
  - add test cases for tgrid
  - refractor: make naming of tgrid and gmsh functions and types corresponding to julia style guide
  - implement and use a general finite volume (linear) mesh general type module
  - implement conversion function from file specific to general mesh format
  - (better) documentation
  - (optional / far future) also implement output file writing to enable file format conversion (optional since the purpose of this package is more the usage of mesh files in other julia packages)

  


