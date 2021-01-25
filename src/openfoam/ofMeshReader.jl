module ofMeshReader
#= 
Functions to:
- Read polymesh in a OpenFOAM Case folder
- Finds and checks the polyMesh folder
- Parse files in polyMesh folder
- Generate OfMesh (ofmeshTypes.jl) from parsed entities

TODO: 
- maybe do some file encoding checking, to avoid encoding errors?
- performance testing and optimization 
- implement unpacking of  gzip files in RAM and procesing with ascii reading
- implement reading of binary dictionary files -> see also ofMeshDictTokenizer.jl
- tests against more differnt meshes
- is some additional masking of neighbour faces necessarry? or are the faces with no neighbour face_owner_cells allways the last faces in faces file, as asumbed now?
=#

include("ofMeshTypes.jl")
include("ofMeshDictParser.jl")

const OfMeshFileType = Dict(
    :ascii => 0,
    :binary => 1,
    :gz => 2
    )

export read_openfoam_mesh

"""
    read_openfoam_mesh()

read, check, parse openfoam mesh
"""
function read_openfoam_mesh(case_path::String)

    # toggle error if necessarry file in case_path/constant/polyMesh non 
    # existent ...
    checkmesh(case_path)

    polymesh_path = joinpath(joinpath(case_path, "constant"), "polyMesh")

    # bf: boundary file
    bf = joinpath(polymesh_path,"boundary")
    # boundary file should be ascii every time ...
    bf_tokens = tokenize_ascii_ofmeshfile(bf)
    bf_preparse = parser(bf_tokens)
    bf_parsed = dfs_parse(bf_preparse, bf_tokens)
    meshinfo = getMeshInfo(bf_parsed, case_path)

    if meshinfo.format == "ascii"
        return parse_mesh(meshinfo, parse_ascii_file)
    else
        error("Binary and Gzip file formats not supported jet!")
    end

end


function checkmesh(case_path::String)

    polymesh_path = joinpath(joinpath(case_path, "constant"), "polyMesh")
    checkdir(polymesh_path)
    checkifmeshfilesexits(polymesh_path)
end


function checkdir(polymesh_path::String)
    
    if !ispath(polymesh_path) || !isdir(polymesh_path)
        error("Folder ", polymesh_path, " not found!")
    end
    return true
end


function checkifmeshfilesexits(polymesh_path::String)

    if !isfile(joinpath(polymesh_path, "boundary"))
        error("File boundary in constant/polyMesh is missing or is not a " *
              "valid file")
    end
    if !isfile(joinpath(polymesh_path, "faces"))
        error("File faces in constant/polyMesh is missing or is not a " *
              "valid file")
    end
    if !isfile(joinpath(polymesh_path, "neighbour"))
        error("File neighbour in constant/polyMesh is missing or is not a" *
              " valid file")
    end
    if !isfile(joinpath(polymesh_path, "owner"))
        error("File owner in constant/polyMesh is missing or is not a " *
              "valid file")
    end
    if !isfile(joinpath(polymesh_path, "points"))
        error("File points in constant/polyMesh is missing or is not a " *
              "valid file")
    end
    return true        
end


"""
    getMeshInfo(bf_parsed::Vector{OfEntity}, case_path::String)

Extract some mesh information out of bounary file 
"""
function getMeshInfo(bf_parsed::Vector{OfEntity}, case_path::String)
    bf = get_dictionary(bf_parsed, "FoamFile")

    if isnothing(bf)
        error("Cannot find file information in bounary file")
    end

    file_version = get_variable_value(bf.entries, "version")
    file_format = get_variable_value(bf.entries, "format")
    file_class = get_variable_value(bf.entries, "class")
    file_rel_location = get_variable_value(bf.entries, "location")
    file_case_path = case_path

    return OfMeshInfo(file_version, file_format, file_class, 
                file_rel_location,file_case_path )

end


function parse_ascii_file(polymesh_path::String, dict_file::String)
    f = joinpath(polymesh_path,dict_file)
    # boundary file should be ascii every time ...
    f_tokens = tokenize_ascii_ofmeshfile(f)
    f_preparse = parser(f_tokens)
    f_parsed = dfs_parse(f_preparse, f_tokens)

    return f_parsed
end


function parse_binary_file()
    # TODO: Implement binary tokenizer / reader
end


function parse_mesh(meshinfo::OfMeshInfo, pasing_fct::Function)

    polymesh_path = joinpath(meshinfo.casepath, meshinfo.location)

    bf_raw = pasing_fct(polymesh_path, "boundary")
    patches = parse_boundary(bf_raw)

    f_raw = pasing_fct(polymesh_path, "faces")
    f = parse_face(f_raw)

    n_raw = pasing_fct(polymesh_path, "neighbour")
    n = parse_neighbour(n_raw)

    o_raw = pasing_fct(polymesh_path, "owner")
    o = parse_owner(o_raw)

    p_raw = pasing_fct(polymesh_path, "points")
    p = parse_point(p_raw::Vector{OfEntity})

    return OfMesh(meshinfo, p, f, patches, o, n)
end


"""
    parse_point(p_raw::Vector{OfEntity})

Parses openfoam point file (from finally parsed tokens) expects an OfArray containing OfArray.length OfLists of OfList.length = 3 with mesh Points in OfValue{Float64}.
"""
function parse_point(p_raw::Vector{OfEntity})

    if typeof(p_raw[2]) == OfArray
        
        n_points = p_raw[2].length
        x = zeros(Float64, n_points)
        y = zeros(Float64, n_points)
        z = zeros(Float64, n_points)

        for (i,p_list) in enumerate(p_raw[2].entries)
            x[i] = p_list.entries[1].value
            y[i] = p_list.entries[2].value
            z[i] = p_list.entries[3].value
        end
    else
        error("Reading points from points file")
    end

    return OfPoints(n_points,x,y,z)
end


function parse_face(f_raw::Vector{OfEntity})

    if typeof(f_raw[2]) == OfArray
        
        no_faces = f_raw[2].length
        face_list = Vector{OfFace}(undef,0)

        for (i,f_list) in enumerate(f_raw[2].entries)

            no_points = f_list.length
            point_List = zeros(Int64, no_points)

            for j = 1:length(f_list.entries)
                point_List[j] = f_list.entries[j].value
            end

            push!(face_list, OfFace(no_points,point_List))
        end

        return OfFaces(no_faces, face_list)
    else
        error("Reading faces from faces file")
    end
end


function parse_boundary(b_raw::Vector{OfEntity})

    if typeof(b_raw[2]) == OfArray

        no_patches = b_raw[2].length
        patches = Vector{OfPatch}(undef, 0)

        for boundary_dict in b_raw[2].entries

            type = get_variable_value(boundary_dict.entries, "type")
            start_face = get_variable_value(boundary_dict.entries, "startFace")
            no_faces = get_variable_value(boundary_dict.entries, "nFaces")

            if isnothing(type) || isnothing(start_face) || isnothing(no_faces)
                error("Reading boundary file from parsed tokens")
            end

            push!(patches, OfPatch(no_faces, start_face, type))
        end

        return patches
    else
        error("Expected Array in boundary file at pos 2 in parsed tokens")
    end

end


function parse_neighbour(n_raw::Vector{OfEntity})
# right now simply assuming that the boundarys begin at the higher numbers 
# of the mesh

    if typeof(n_raw[2]) == OfArray
            
        n_internal_faces = n_raw[2].length
        face_neighbour_cells = zeros(Int64, n_internal_faces)

        for (i,n) in enumerate(n_raw[2].entries)
            face_neighbour_cells[i] = n.value
        end
    else
        error("Reading points from points file")
    end

    return face_neighbour_cells
end


function parse_owner(o_raw::Vector{OfEntity})
    if typeof(o_raw[2]) == OfArray
        
        n_faces = o_raw[2].length
        face_owner_cells = zeros(Int64, n_faces)

        for (i,o) in enumerate(o_raw[2].entries)
            face_owner_cells[i] = o.value
        end

    else
        error("Reading points from points file")
    end

    return face_owner_cells
end

end