#= 
Final parsing of preparsing structures

Numbers and variables will finaly
=#
include("ofMeshDictPreParser.jl")

abstract type OfEntity end
abstract type AbstractOfVar <: OfEntity end
abstract type AbstractOfVal <: OfEntity end

struct OfDictionary <: OfEntity
    name::String
    entries::Vector{OfEntity}
end

# array list of same entities with length 
struct OfArray <: OfEntity
    length::Int64
    entries::Vector{OfEntity}
end

struct OfList<: OfEntity
    length::Int64
    entries::Vector{OfEntity}
end

struct OfVariable{T} <: AbstractOfVar
    name::String
    value::T
end

struct OfValue{T} <: AbstractOfVal
    value::T
end


"""
    dfs_parse(parse_entities::Vector{PreParsedEntity}, tokens::Vector{Token})

parses pre parsed vector structure to finally parsed file structure
"""
function dfs_parse(parse_entities::Vector{PreParsedEntity}, tokens::Vector{Token})

    of_entities = Vector{OfEntity}(undef, 0)

    for parse_elem in parse_entities
        if typeof(parse_elem) == PreParsedVariable    
            push!(of_entities, parse_of_variable(parse_elem, tokens))
        elseif typeof(parse_elem) == PreParsedFNum
            push!(of_entities, OfValue(parse(Float64,parse_elem.string)))
        elseif typeof(parse_elem) == PreParsedINum
            push!(of_entities, OfValue(parse(Int64,parse_elem.string)))
        elseif typeof(parse_elem) == PreParsedDictonary
            mypush!(of_entities, OfDictionary(parse_elem.name,
                        dfs_parse(parse_elem.entries, tokens)))
        elseif typeof(parse_elem) == PreParsedArray
            mypush!(of_entities, OfArray(parse_elem.length, 
                        dfs_parse(parse_elem.entries, tokens)))
        elseif typeof(parse_elem) == PreParsedList
            parsed_list = dfs_parse(parse_elem.entries, tokens)
            mypush!(of_entities, OfList(length(parsed_list), parsed_list))
        end
    end

    return of_entities
end


function mypush!(of_entities::Vector{OfEntity}, OfEntity::T) where T <: OfEntity
    push!(of_entities, OfEntity)
end


function mypush!(of_entities::Vector{OfEntity},
                    entities::Vector{T}) where T <: OfEntity
    for e in entities
        push!(of_entities, e)
    end
end


"""
    parse_of_variable(pe::PreParsedEntity, tokens::Vector{Token})

Parsing of a PreParsedEntity to final type OfVariable, which completes parsing.
"""
# TODO: only works for numbers and strings by now
function parse_of_variable(pe::PreParsedEntity, tokens::Vector{Token})::OfVariable
    
    name = ""
    value = []

    if tokens[pe.id_token_from].type_id == TokenTypeID_Dict[:word]
        name = tokens[pe.id_token_from].string

        if ( (pe.id_token_to - pe.id_token_from) == 2 )
            if  (tokens[pe.id_token_from+1].type_id == 
                 TokenTypeID_Dict[:int_number])

                value = parse(Int64, tokens[pe.id_token_from+1].string)

            elseif (tokens[pe.id_token_from+1].type_id == 
                    TokenTypeID_Dict[:float_number])

                value = parse(Float64, tokens[pe.id_token_from+1].string)

            elseif (tokens[pe.id_token_from+1].type_id 
                    == TokenTypeID_Dict[:word])

                value = tokens[pe.id_token_from+1].string

            elseif (tokens[pe.id_token_from+1].type_id 
                == TokenTypeID_Dict[:string])
                
                value = tokens[pe.id_token_from+1].string

            else
                value = nothing
            end
        elseif ( ((pe.id_token_to - pe.id_token_from) == 3) &&
                 (tokens[pe.id_token_from+1].type_id == 
                        TokenTypeID_Dict[:minus]) )

            if  (tokens[pe.id_token_from+2].type_id == 
                TokenTypeID_Dict[:int_number])

                value = parse(Int64, tokens[pe.id_token_from+1].string * 
                                        tokens[pe.id_token_from+2].string)

            elseif (tokens[pe.id_token_from+2].type_id == 
                    TokenTypeID_Dict[:float_number])

                 value = parse(Float64, tokens[pe.id_token_from+1].string *  
                                        tokens[pe.id_token_from+2].string)
            else
                value =  nothing
            end

        else
            value = 0
        end
    else
        error("First Token of Variable should be a word!")
    end

    return OfVariable(name, value)
end


"""
    ofprint(ofvar::OfEntity, depth::Int64=0)

dfs print in case for single OfEntity
"""
function ofprint(ofvar::OfEntity, depth::Int64=0)
    ofprint([ofvar], depth)
end


"""
    ofprint(ofvars::Vector{OfEntity}, depth::Int64=0) 

dfs print of Vector{OfEntity} to get a nicer view of finally parsed entities
"""
function ofprint(ofvars::Vector{OfEntity}, depth::Int64=0)    
    for ofvar in ofvars
        if typeof(ofvar) <: AbstractOfVar   
            println("\t"^depth,ofvar.name, ": ", ofvar.value)

        elseif typeof(ofvar) <: AbstractOfVal
            print(ofvar.value, " ")

        elseif typeof(ofvar) == OfDictionary
            println()
            println("\t"^depth,ofvar.name, " {")
            depth += 1
            ofprint(ofvar.entries, depth)
            depth -= 1
            println("\t"^depth,"}")
        elseif typeof(ofvar) == OfArray
            print("\t"^depth,ofvar.length, " (")
            depth += 1
            ofprint(ofvar.entries,depth)
            print(")\n")
            depth -= 1
        elseif typeof(ofvar) == OfList
            print("\t"^depth,"(")
            ofprint(ofvar.entries, depth)
            print(")\n")
        end
    end

end

"""
    get_dictionary(ofvars::Vector{OfEntity}, dict_name::string)

Returns Dictionary in first layer of ofvars with .name == dict_name
"""
function get_dictionary(ofvars::Vector{OfEntity}, dict_name::String)

    for f in ofvars
        if typeof(f) == OfDictionary && f.name == dict_name
            return f
        end
    end

    return nothing
end



"""
    get_variable(ofvars::Vector{OfEntity}, var_name::string)

Returns Variable in first layer of ofvars with .name == var_name
"""
function get_variable(ofvars::Vector{OfEntity}, var_name::String)

    for f in ofvars
        if typeof(f) <: AbstractOfVar && f.name == var_name
            return f
        end
    end

    return nothing
end



"""
    get_variable_value(ofvars::Vector{OfEntity}, var_name::string)

Returns Variable value in first layer of ofvars with .name == var_name
"""
function get_variable_value(ofvars::Vector{OfEntity}, var_name::String)

    var = get_variable(ofvars::Vector{OfEntity}, var_name::String)

    if !isnothing(var)
        return var.value
    else
        error("Variable ", var_name, " cannot be found")
    end

end
