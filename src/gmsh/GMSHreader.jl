module GMSHreader
#=
Read GMSH files:

Supported MeshFormat 4, ASCII

Supported File Groups:
    - MeshFomrat
    - PhysicalNames
    - Entities
    - Nodes
    - Elements

GMSH Element Types:
1:  2-node line.
2:  3-node triangle.
3:  4-node quadrangle.
4:  4-node tetrahedron.
5:  8-node hexahedron.
6:  6-node prism.
7:  5-node pyramid.
8:  3-node second order line (2 nodes associated with the vertices and 1
    with the edge).
9:  6-node second order triangle (3 nodes associated with the vertices and 3
    with the edges).
10: 9-node second order quadrangle (4 nodes associated with the vertices,
    4 with the edges and 1 with the face).
11: 10-node second order tetrahedron (4 nodes associated with the vertices and
    6 with the edges).
12: 27-node second order hexahedron (8 nodes associated with the vertices,
    12 with the edges, 6 with the faces and 1 with the volume).
13: 18-node second order prism (6 nodes associated with the vertices,
    9 with the edges and 3 with the quadrangular faces).
14: 14-node second order pyramid (5 nodes associated with the vertices,
    8 with the edges and 1 with the quadrangular face).
15: 1-node point.
16: 8-node second order quadrangle (4 nodes associated with the vertices and
    4 with the edges).
17: 20-node second order hexahedron (8 nodes associated with the vertices and
    12 with the edges).
18: 15-node second order prism (6 nodes associated with the vertices and 9
    with the edges).
19: 13-node second order pyramid (5 nodes associated with the vertices
    and 8 with the edges).
20: 9-node third order incomplete triangle (3 nodes associated with the
    vertices, 6 with the edges)
21: 10-node third order triangle (3 nodes associated with the vertices,
    6 with the edges, 1 with the face)
22: 12-node fourth order incomplete triangle (3 nodes associated with the
    vertices, 9 with the edges)
23: 15-node fourth order triangle (3 nodes associated with the vertices,
    9 with the edges, 3 with the face)
24: 15-node fifth order incomplete triangle (3 nodes associated with the vertices,
    12 with the edges)
25: 21-node fifth order complete triangle (3 nodes associated with the vertices,
    12 with the edges, 6 with the face)
26: 4-node third order edge (2 nodes associated with the vertices, 2 internal
    to the edge)
27: 5-node fourth order edge (2 nodes associated with the vertices, 3 internal
    to the edge)
28: 6-node fifth order edge (2 nodes associated with the vertices, 4 internal
    to the edge)
29: 20-node third order tetrahedron (4 nodes associated with the vertices,
    12 with the edges, 4 with the faces)
30: 35-node fourth order tetrahedron (4 nodes associated with the vertices,
    18 with the edges, 12 with the faces, 1 in the volume)
31: 56-node fifth order tetrahedron (4 nodes associated with the vertices,
    24 with the edges, 24 with the faces, 4 in the volume)
92: 64-node third order hexahedron (8 nodes associated with the vertices,
    24 with the edges, 24 with the faces, 8 in the volume)
93: 125-node fourth order hexahedron (8 nodes associated with the vertices,
    36 with the edges, 54 with the faces, 27 in the volume)
=#

export readGMSH

include("GMSHtypes.jl")


function readGMSH(filename::String)
    io = open(filename, "r")
    blockTypes, blocks = loopGMSHFileBlockSections(io)
    gmsh = evaluatGMSHBlockSections(blockTypes, blocks)

    return gmsh
end


function loopGMSHFileBlockSections(io)

    blocks = String[]
    blockTypes = String[]
    iobuff = IOBuffer(UInt8[], read=true, write=true, append=true)

    for line in eachline(io)
        if line[1] =='$'

            if line[1:4] == "\$End"
                push!(blocks, read(iobuff,String))
            else
                push!(blockTypes, line)
            end

            flush(iobuff)
        else
            write(iobuff, line * "\n")
        end
    end

    return blockTypes, blocks
end


function evaluatGMSHBlockSections(blockTypes::Array{String,1}, blocks)
    fileInfo=[]
    gmshPhysicalEntities=[]
    entities=[]
    nodes=[]
    elementGroups=[]

    for i=1:size(blockTypes,1)
        println(blockTypes[i])

        blockLines = split(blocks[i], "\n")
        blockLines = blockLines[blockLines .!= ""]

        if blockTypes[i] == "\$MeshFormat"
            fileInfo = evalMeshFormat(blockLines)
            println("File Version:",fileInfo.version_number)
            println("File Type:",fileInfo.file_type)
            println("Data Size:",fileInfo.data_size)

        elseif blockTypes[i] == "\$PhysicalNames"
            gmshPhysicalEntities = evalPhysicalNames(blockLines, fileInfo)

        elseif blockTypes[i] == "\$Entities"
            entities = evalEntities(blockLines, fileInfo)

        elseif blockTypes[i] == "\$Nodes"
            nodes = evalNodesBlock(blockLines, fileInfo)

        elseif blockTypes[i] == "\$Elements"
            elementGroups = evalElementsBlock(blockLines, fileInfo)

        end
    end

    # may not be defined in every gmsh file
    if typeof(gmshPhysicalEntities) == Array{Any,1}
        gmshPhysicalEntities = PhysicalEntities(0, nothing)
    end

    gmsh = GMSH(fileInfo, gmshPhysicalEntities, entities, nodes, elementGroups)

    return gmsh
end


function evalMeshFormat(blockContent::Array{SubString{String},1})

    if size(blockContent,1) <= 1
        s = split(blockContent[1], " ")

        fileInfo = GMSHFileInfo(parse(Float64, s[1]), parse(Int64, s[2]), parse(Int64, s[3]))

    else
        @error "Uknown size of MeshFormat Block in GMSHreader!"
    end

    return fileInfo
end


function evalPhysicalNames(blockContent::Array{SubString{String},1}, 
        fileinfo::GMSHFileInfo)

    count = parse(Int64,blockContent[1])
    entitiesBlock = blockContent[2:end]
    entities = Array{PhysicalEntity,1}(undef, size(entitiesBlock,1));

    for i = 1 : size(entitiesBlock,1)
        s = split(entitiesBlock[i], r" ")

        if size(s,1) > 3
            name = join(s[3:size(s,1)])
        else
            name = s[3];
        end

        entities[i] = PhysicalEntity(parse(UInt8, s[1]), parse(Int64, s[2]), name)
    end

    gmshPhysicalEntities = PhysicalEntities(parse(Int64, blockContent[1]) ,entities)
    return gmshPhysicalEntities
end


function evalEntityBlock(BlockContent::Array{SubString{String},1}, type::Int64, fileInfo::GMSHFileInfo)
    #=
    Entity Block String eval:
    type:
    1: Point
    2: Curve
    3: Surface
    4: volume
    =#

    if type == gmsh_tag_type["Point"]
        Entity = Array{Point,1}(undef, size(BlockContent,1))
    elseif type == gmsh_tag_type["Curve"]
        Entity = Array{Curve,1}(undef, size(BlockContent,1))
    elseif type == gmsh_tag_type["Surface"]
        Entity = Array{Surface,1}(undef, size(BlockContent,1))
    elseif type == gmsh_tag_type["Volume"]
        Entity = Array{Volume,1}(undef, size(BlockContent,1))
    else
        @error "unknow type"
    end

    for i=1:1:size(BlockContent,1)
        s = split(BlockContent[i], " ")
        tag = parse(Int64, s[1])

        if type == gmsh_tag_type["Point"]

            x = parse(Float64, s[2])
            y = parse(Float64, s[3])
            z = parse(Float64, s[4])

            if isapprox(fileInfo.version_number,4.0)
                # 8 = Bug in GMSH Doku oder Implementierung für Points...
                # Doku:
                # http://gmsh.info/doc/texinfo/gmsh.html#MSH-file-format
                #=
                pointTag(int) X(double) Y(double) Z(double)
                numPhysicalTags(size_t) physicalTag(int) ...
                ...
                Allerdings sind x y z doppelt besetzt ...
                =#
                numPhysicalTags = parse(Int64, s[8])
                physicalTag = Array{Int,1}(undef, numPhysicalTags)
    
            elseif isapprox(fileInfo.version_number,4.1)
                numPhysicalTags = parse(Int64, s[5])
                physicalTag = Array{Int,1}(undef, numPhysicalTags)
            else
                error("Unknown gmsh file version")
            end
        else
            xmin = parse(Float64, s[2])
            ymin = parse(Float64, s[3])
            zmin = parse(Float64, s[4])
            xmax = parse(Float64, s[5])
            ymax = parse(Float64, s[6])
            zmax = parse(Float64, s[7])
        end
        
        if type != gmsh_tag_type["Point"]
            numPhysicalTags = parse(Int64, s[8])
            physicalTag = Array{Int,1}(undef, numPhysicalTags)

            # TODO: what todo when points have physical tags?
            if numPhysicalTags > 0
                m = 1
                for k=9:1:(8+numPhysicalTags)
                    physicalTag[m] = parse(Int64, s[k])
                    m += 1
                end
            end

            numBoundingElements = parse(Int64, s[9+numPhysicalTags])
            boundingElementTag = Array{Int64,1}(undef, numBoundingElements)

            if numBoundingElements > 0
                m = 1
                for k=(10+numPhysicalTags):1:(9+numPhysicalTags+numBoundingElements)
                    boundingElementTag[m] = parse(Int64, s[k])
                    m += 1
                end
            end
        end

        if type == gmsh_tag_type["Point"]
            Entity[i] = Point(tag, x, y, z, numPhysicalTags, physicalTag)
        elseif type == gmsh_tag_type["Curve"]
            Entity[i] = Curve(tag, xmin, ymin, zmin, xmax, ymax, zmax,
                        numPhysicalTags, physicalTag, numBoundingElements,
                        boundingElementTag)
        elseif type == gmsh_tag_type["Surface"]
            Entity[i] = Surface(tag, xmin, ymin, zmin, xmax, ymax, zmax,
                        numPhysicalTags, physicalTag, numBoundingElements,
                        boundingElementTag)

        elseif type == gmsh_tag_type["Volume"]
            Entity[i] = Volume(tag, xmin, ymin, zmin, xmax, ymax, zmax,
                        numPhysicalTags, physicalTag, numBoundingElements,
                        boundingElementTag)
        end
    end

    return Entity
end


function evalEntities(blockContent::Array{SubString{String},1},fileinfo::GMSHFileInfo)

    s = split(blockContent[1], " ")

    if size(s,1) == 4
        numPoints = parse(Int64, s[1])
        numCurves = parse(Int64, s[2])
        numSurfaces = parse(Int64, s[3])
        numVolumes = parse(Int64, s[4])

        numAllEntities = numPoints+numCurves+numSurfaces+numVolumes

        if size(blockContent,1) == (1+numAllEntities)
            Points = evalEntityBlock(blockContent[2:(numPoints+1)],
                                        gmsh_tag_type["Point"], fileinfo)
            Curves = evalEntityBlock(
                            blockContent[(numPoints+2):(numPoints+numCurves+1)],
                            gmsh_tag_type["Curve"], fileinfo )
            Surfaces = evalEntityBlock(
                            blockContent[(numPoints+numCurves+2):(numPoints
                                                 +numCurves+numSurfaces+1)],
                            gmsh_tag_type["Surface"], fileinfo)
            Volumes = evalEntityBlock(blockContent[(numPoints+numCurves+
                                            numSurfaces+2):(numPoints+
                                            numCurves+numSurfaces+
                                            numVolumes+1)],
                                        gmsh_tag_type["Volume"], fileinfo)

            entities = MeshEntities(Points, Curves, Surfaces, Volumes)
            return entities
        else
            @error "Wrong number of lines in entities block"
        end

        println(numPoints, numCurves, numSurfaces, numVolumes)

    else
        @error "Unknown size of first line in entities block"
    end

end

function evalNodesBlock(blockContent::Array{SubString{String},1},fileinfo::GMSHFileInfo)
    println("evalNodes");
    #=
        size(blockContent[2:end]) - numEntities == numNodes
        that means that each Node is exclusive to its entity no double entities for nodes!
    =#
    s = split(blockContent[1], " ")
    numEntities = parse(Int64, s[1])
    numNodes = parse(Int64, s[2])

    println("numEntities: ", numEntities)
    println("numNodes: ", numNodes)

    x = zeros(Real, numNodes)
    y = zeros(Real, numNodes)
    z = zeros(Real, numNodes)
    nodenum = zeros(Int64, numNodes)
    nenteties = zeros(Int64, numNodes)
    ckecked = falses(numNodes)
    entityTags = zeros(Int64, numNodes)
    entityTypeIDs = zeros(Int64, numNodes)

    offset = 2;
    ni = 1
    for i = 1:numEntities
        si = split(blockContent[offset], " ")
        entityTag = parse(Int64, si[1])
        entityTypeID = parse(Int64, si[2])
        numEntityNodes = parse(Int64, si[end])

        if isapprox(fileinfo.version_number, 4.0)
            blockNodes=blockContent[(offset+1):(offset+numEntityNodes)]
            println("Node entity ", i, " has ", size(blockNodes,1), " nodes")

            for si in blockNodes
                sj = split(si, " ")
                node = parse(Int64, sj[1])

                if ckecked[ni]
                    @warn "dual cells checked, should not happen"
                else
                    ckecked[ni] = true
                end

                nodenum[ni] = node
                x[ni] = parse(Float64, sj[2])
                y[ni] = parse(Float64, sj[3])
                z[ni]= parse(Float64, sj[4])
                nenteties[ni] += 1
                entityTypeIDs[ni] = entityTypeID
                entityTags[ni] = entityTag

                ni += 1
            end

            offset = offset + numEntityNodes + 1

        elseif isapprox(fileinfo.version_number, 4.1)

            blockNodesNum = blockContent[(offset+1):(offset+numEntityNodes)]
            blockNodesCoords = blockContent[(offset+1+numEntityNodes):(offset+numEntityNodes+numEntityNodes)]
            println("Node entity ", i, " has ", size(blockNodesNum,1), " nodes")

            ni_temp = ni
            for si in blockNodesNum 
                sj = split(si, " ")
  
                node = parse(Int64, sj[1])
    
                if ckecked[ni_temp]
                    @warn "dual cells checked, should not happen"
                else
                    ckecked[ni_temp] = true
                end
    
                nodenum[ni_temp] = node 

                nenteties[ni_temp] += 1
                entityTypeIDs[ni_temp] = entityTypeID
                entityTags[ni_temp] = entityTag
    
                ni_temp += 1
            end
    

            for si in blockNodesCoords 
                sj = split(si, " ")
    
                x[ni] = parse(Float64, sj[1])
                y[ni] = parse(Float64, sj[2])
                z[ni]= parse(Float64, sj[3])
    
                ni += 1
            end

            offset = offset + numEntityNodes + numEntityNodes + 1
        end
    end

    p = sortperm(nodenum)

    nodes = Nodes(nodenum[p], x[p], y[p], z[p], nenteties[p], entityTypeIDs[p],
                    entityTags[p])

    return nodes
end


function evalElementLine(blockContent::SubString{String}, elementTypeID::Int)
    s = split(blockContent, " ")
    s = s[s .!= ""]

    no_nodes =  elementTypeID_NodeCount[elementTypeID]
    number = parse(Int64, s[1])

    if no_nodes == size(s[2:end],1)
        nodes = Array{Int,1}(undef, no_nodes)

        for i = 1:no_nodes
            nodes[i] = parse(Int64,s[i+1])
        end

        element = Element(number, nodes)
        return element
    else
        @error "Element Type Node Count not equal Found Nodes"
    end

end


function evalElementBlock(blockContent::Array{SubString{String},1},entityTag::Int,
                     entityTypeID::Int, numEntityElements::Int, elementTypeID::Int64)

    elements = Array{Element, 1}(undef, numEntityElements)

    for i=1:1:numEntityElements
        elements[i] = evalElementLine(blockContent[i], elementTypeID)
    end

    elementGroup = ElementGroup(entityTag, entityTypeID, elementTypeID,
                                                numEntityElements, elements)

    return elementGroup
end


function evalElementsBlock(blockContent::Array{SubString{String},1},fileinfo::GMSHFileInfo)
    println("evalElements");

    s = split(blockContent[1], " ")
    numEntities = parse(Int64, s[1])
    numElements = parse(Int64, s[2])

    println("numEntities: ", numEntities)
    println("numElements: ", numElements)

    elementGroups = Array{ElementGroup,1}(undef, numEntities)

    offset = 2;
    for i = 1:numEntities

        si = split(blockContent[offset], " ")
        entityTag = parse(Int64, si[1])
        entityTypeID = parse(Int64, si[2])
        elementTypeID = parse(Int64, si[3])
        numEntityElements = parse(Int64, si[end])

        println("Elements entity ", i, " has ", numEntityElements, " elements")

        elementGroups[i] = evalElementBlock(blockContent[offset+1:offset+numEntityElements],
                            entityTag, entityTypeID, numEntityElements, elementTypeID)

        offset = offset + numEntityElements + 1
    end

    return elementGroups

end

end
