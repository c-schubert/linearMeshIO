module TGridReader
#=
This module can read fluent .msh files in ascii formating
=#
include("TGridTypes.jl")

export TgridMeshImport

function TgridMeshImport(filename::String)
    io = Base.open(filename, "r")
    sections = loopGridSections(io)
    
    myTGrid = evalSections(sections)
    return myTGrid
end

function loopGridSections(io)
    sections = gridSectionStruct[]
    iobuff = IOBuffer(UInt8[], read=true, write=true, append=true)
    openbrackets = 0
    closedbrackets= 0

    for line in eachline(io)

            for s in line
                if s == '('
                    if openbrackets > 0
                        push!(sections, gridSectionStruct(openbrackets, read(iobuff,String)))
                        flush(iobuff)
                    end
                    openbrackets = openbrackets + 1
                elseif s == ')'
                    closedbrackets = closedbrackets + 1
                else
                    write(iobuff, s);
                end

                if openbrackets == closedbrackets
                    write(iobuff, "\n")
                    push!(sections, gridSectionStruct(openbrackets, read(iobuff,String)))
                    flush(iobuff)
                    openbrackets = 0
                    closedbrackets = 0
                end
            end

            if openbrackets != closedbrackets
                write(iobuff, "\n")
            end
    end

    if openbrackets != closedbrackets
        @error "Unbalances brackets in file"
    end

    return sections
end


function evalSections(sections::Array{gridSectionStruct, 1})
    mainGridID = -1
    dimensions = -1
    header = ""
    nodesSections = NodeSection[]
    cellSections = CellSection[]
    faceSections = FaceSection[]
    namedZones = NamedZone[]
    zoneID = -1
    firstIdx = 0
    lastIdx = 0
    type = -1
    cellType = -1
    faceType = -1
    i = 0

    for (k, sec) in enumerate(sections)
        
        if sec.gridIDx == 1
            s = split(sec.content, " ")
            contentArr = s[s .!= ""]

            mainGridID = parse(Int64, contentArr[1])

            if  length(contentArr) > 1

                if mainGridID == xfgridsections["xf-dimension"]
                    dimensions = parse(Int64, contentArr[2])
                end

                if mainGridID == xfgridsections["xf-header"]
                    header = contentArr[2:end]
                end

            end
            i = 1

        else
            if mainGridID == xfgridsections["xf-comment"]
                #empty

            elseif mainGridID == xfgridsections["xf-node"]
                s = split(sec.content, " ")
                contentArr = s[s .!= ""]

                if i == 1
                    s = split(sec.content, " ")
                    contentArr = s[s .!= ""]
                    zoneID = parse(Int64, contentArr[1], base=16)

                    if zoneID == 0
                        firstIdx = 1
                        lastIdx = parse(Int64, contentArr[3], base=16)
                        push!(nodesSections, NodeSection(zoneID, firstIdx, lastIdx, nothing))
                    else
                        firstIdx = parse(Int64, contentArr[2], base=16)
                        lastIdx = parse(Int64, contentArr[3], base=16)
                    end
                elseif i==2
                    s = split(sec.content, r" |\n")
                    contentArr = s[s .!= ""]

                    if dimensions == 3
                        x = parse.(Float64, contentArr[1:3:end])
                        y = parse.(Float64, contentArr[2:3:end])
                        z = parse.(Float64, contentArr[3:3:end])
                    elseif dimensions == 2
                        x = parse.(Float64, contentArr[1:2:end])
                        y = parse.(Float64, contentArr[2:2:end])
                    else
                        @error "wrong size of dimensions in node section"
                    end

                    if dimensions == 3
                        push!(nodesSections, NodeSection(zoneID, firstIdx, lastIdx, [x y z]))
                    elseif dimensions == 2
                        push!(nodesSections, NodeSection(zoneID, firstIdx, lastIdx, [x y]))
                    end
                else
                    @warn "Wrong size of subsections in node section"
                end

            elseif mainGridID == xfgridsections["xf-periodic-face"]
                # not implemented jet
                @warn "xf-periodic-face no implemented jet"

            elseif mainGridID == xfgridsections["xf-cell"]
                s = split(sec.content, " ")
                contentArr = s[s .!= ""]

                if i == 1
                    s = split(sec.content, " ")
                    contentArr = s[s .!= ""]
                    zoneID = parse(Int64, contentArr[1], base=16)

                    if zoneID == 0
                        firstIdx = 1
                        lastIdx = parse(Int64, contentArr[3], base=16)
                        type = 0
                        cellType = -1
                    else
                        firstIdx = parse(Int64, contentArr[2], base=16)
                        lastIdx = parse(Int64, contentArr[3], base=16)
                        type = parse(Int64, contentArr[4])
                        cellType = parse(Int64, contentArr[5])
                    end

                    if cellType != 0
                        push!(cellSections, CellSection(zoneID, firstIdx,
                        lastIdx, type, cellType, nothing))
                    end

                elseif i==2
                    if cellType == 0
                        s = split(sec.content, r" |\n")
                        contentArr = s[s .!= ""]

                        mixedCellTypes = parse.(Int, contentArr)
                        push!(cellSections, CellSection(zoneID, firstIdx,
                            lastIdx, type, cellType, mixedCellTypes))
                    else
                        @warn "This should not occur possible parsing error of cell section..."
                    end

                else
                    @warn "Wrong size of subsections in cell section"
                end
            elseif mainGridID == xfgridsections["xf-face"]

                s = split(sec.content, " ")
                contentArr = s[s .!= ""]

                if i == 1
                    s = split(sec.content, " ")
                    contentArr = s[s .!= ""]
                    #println(contentArr[1])
                    zoneID = parse(Int64, contentArr[1], base=16)

                    if zoneID == 0
                        firstIdx = 1
                        lastIdx = parse(Int64, contentArr[3], base=16)
                        type = 0
                        faceType = -1
                        push!(faceSections, FaceSection(zoneID, firstIdx,
                        lastIdx, type, faceType, nothing))
                    else
                        firstIdx = parse(Int64, contentArr[2], base=16)
                        lastIdx = parse(Int64, contentArr[3], base=16)
                        type = parse(Int64, contentArr[4])
                        faceType = parse(Int64, contentArr[5])
                    end

                elseif i==2
                    localFaceType = 0
                    s = split(sec.content, "\n")
                    contentArr = s[s .!= ""]
                    faces = Array{Face,1}(undef, length(contentArr))

                    if faceType == 0
                        for (ii, ss) in enumerate(contentArr)
                            sss = split(ss, " ")
                            contentArr1 = sss[sss .!= ""]
                            localFaceType = parse(Int64, contentArr1[1])

                            faceNodes = facetype_nodes_per_face[localFaceType]

                            nodes = parse(Int64, contentArr1[2:(1+faceNodes)], base=16)
                            cr = parse(Int64, contentArr1[(2+faceNodes)], base=16)
                            cl = parse(Int64, contentArr1[(3+faceNodes)], base=16)

                            faces[ii] =  Face(localFaceType, nodes, cr, cl)
                        end
                    else
                        localFaceType = faceType
                        faceNodes = facetype_nodes_per_face[localFaceType]

                        for (ii, ss) in enumerate(contentArr)
                            sss = split(ss, " ")
                            contentArr1 = sss[sss .!= ""]

                            nodes = parse.(Int64, contentArr1[1:faceNodes], base=16)
                            cr = parse(Int64, contentArr1[(1+faceNodes)], base=16)
                            cl = parse(Int64, contentArr1[(2+faceNodes)], base=16)

                            faces[ii] =  Face(localFaceType, nodes, cr, cl)
                        end

                    end

                    push!(faceSections, FaceSection(zoneID, firstIdx,
                    lastIdx, type, faceType, faces))
                else
                    @warn "Wrong size of subsections in face section"
                end

            elseif mainGridID == xfgridsections["xf-face-tree"]
                # not implemented jet
                @warn "xf-face-tree no implemented jet"

            elseif mainGridID == xfgridsections["xf-cell-tree"]
                # not implemented jet
                @warn "xf-cell-tree no implemented jet"

            elseif mainGridID == xfgridsections["xf-face-parents"]
                # not implemented jet
                @warn "xf-face-parents no implemented jet"

            elseif mainGridID == xfgridsections["xf-zone"]
                s = split(sec.content, " ")
                contentArr = s[s .!= ""]

                if i == 1
                    s = split(sec.content, " ")
                    contentArr = s[s .!= ""]
                    zoneID = parse(Int64, contentArr[1], base=16)
                    zoneType = contentArr[2]
                    zoneName = contentArr[3]

                    push!(namedZones, NamedZone(zoneID, zoneType, zoneName))
                elseif i==2

                else
                    @warn "Wrong size of subsections in face section"
                end

            else
                @warn "no fitting parsing for given main ID"
            end

            i = i + 1;


        end
    end

  myTGrid= TGrid(header, dimensions, cellSections, faceSections, nodesSections, namedZones)

return myTGrid
end


end
