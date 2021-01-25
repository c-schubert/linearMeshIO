#= 
Parse tokenized foam file to kind of AST with some unparsed token Content
ofmeshtypes over PreParsedDictonaryonary types 

numbers and varaibles will not finally be parsed in this stage:
    preparse entities contain index of tokens or strings that are not completly 
    parsed jet
=#

include("ofMeshDictTokenizer.jl")

const ParseEntitySymbols_Dict = Dict(
    :word => TokenTypeID_Dict[:word],
    :def_var_end => TokenTypeID_Dict[:semicolon],
    :dict_start => TokenTypeID_Dict[:curly_brace_open],
    :dict_end => TokenTypeID_Dict[:curly_brace_close],
    :arr_start => TokenTypeID_Dict[:bracket_open],
    :arr_end => TokenTypeID_Dict[:bracket_close],
)
        
const ParseSymbolsEntity_Dict = Dict(value => key for (key, value) in TokenTypeID_Dict)

abstract type PreParsedEntity end
abstract type PreParsedNum <: PreParsedEntity end


mutable struct PreParsedFNum <: PreParsedNum
    string::String
end


mutable struct PreParsedINum <: PreParsedNum
    string::String
end


mutable struct PreParsedVariable <: PreParsedEntity
    id_token_from::Int64
    id_token_to::Int64
end


mutable struct PreParsedDictonary <: PreParsedEntity
    id_token_from::Int64
    id_token_to::Int64
    name::String
    entries::Vector{PreParsedEntity}
end


# array list of same entities with length 
mutable struct PreParsedArray <: PreParsedEntity
    id_token_from::Int64
    id_token_to::Int64
    length::Int64
    entries::Vector{PreParsedEntity}
end


# same as array but no defined length
mutable struct PreParsedList <: PreParsedEntity
    id_token_from::Int64
    id_token_to::Int64
    entries::Vector{PreParsedEntity}
end


"""
    parser(tokens::Vector{Token}, i_start::Int64=1, i_stop::Int64=-1)

pre parsing of tokens to array structure that represents file structure
"""
function parser(tokens::Vector{Token}, i_start::Int64=1, 
                                    i_stop::Int64=-1)::Vector{PreParsedEntity}
    
    i = i_start

    if i_stop == -1
        i_stop = length(tokens)
    end

    parse_entities = Vector{PreParsedEntity}(undef,0)

    while i  <= i_stop
        t = tokens[i]

        if t.type_id == ParseEntitySymbols_Dict[:word]
            
            if tokens[i+1].type_id == ParseEntitySymbols_Dict[:dict_start]
                i_end = find_closing(tokens, i+1, tokens[i+1].type_id)
                dict_entities = parser(tokens, i+2, i_end-1)

                dict_name = tokens[i].string

                push!(parse_entities, PreParsedDictonary(i+1, i_end, dict_name, dict_entities))
                i_next = i_end + 1
            else
                i_end = get_end_of_ofvar(tokens, i+1)
                push!(parse_entities, PreParsedVariable(i, i_end))
                i_next  = i_end + 1
            end
        elseif t.type_id == ParseEntitySymbols_Dict[:arr_start]
            i_end = find_closing(tokens, i, t.type_id)
            
            if tokens[i-1].type_id == TokenTypeID_Dict[:int_number]
                arr_len = parse(Int64, tokens[i-1].string)

                arr_entities = parser(tokens, i+1, i_end-1)  
                check_correct_arr_list!(arr_entities)
                push!(parse_entities, PreParsedArray(i, i_end, arr_len, arr_entities))
            else
                list_entities = parser(tokens, i+1, i_end-1)
                check_correct_arr_list!(list_entities)
                push!(parse_entities, PreParsedList(i, i_end, list_entities))
            end
            
            i_next = i_end + 1
        elseif t.type_id == TokenTypeID_Dict[:minus]

            if tokens[i+1].type_id == TokenTypeID_Dict[:float_number]
                push!(parse_entities, PreParsedFNum(tokens[i].string * 
                                                  tokens[i+1].string))
                i_next = i+2
                    
            elseif tokens[i+1].type_id == TokenTypeID_Dict[:int_number]
                push!(parse_entities, PreParsedINum(tokens[i].string * 
                                                  tokens[i+1].string))
                i_next = i+2
            end

        elseif t.type_id == TokenTypeID_Dict[:float_number]
            push!(parse_entities, PreParsedFNum(tokens[i].string))
            i_next = i+1
        elseif  (t.type_id == TokenTypeID_Dict[:int_number] 
                 && tokens[i+1].type_id != TokenTypeID_Dict[:bracket_open])
            push!(parse_entities, PreParsedINum(tokens[i].string))
            i_next = i+1
        else
            i_next = i + 1
        end

        i = i_next
    end

    return parse_entities
end


"""
    get_closing(tid_opening::Int64)::Int64

get matching closing bracket id
"""
function get_closing(tid_opening::Int64)::Int64

    if tid_opening == TokenTypeID_Dict[:bracket_open]
        tid_closing = TokenTypeID_Dict[:bracket_close]
        
    elseif tid_opening == TokenTypeID_Dict[:curly_brace_open]
        tid_closing = TokenTypeID_Dict[:curly_brace_close]

    else
        error("invalid charcter id to find matching closing bracket(char)")
    end

    return tid_closing
end


"""
    get_end_of_ofvar(tokens::Vector{Token}, i_start::Int64)

find end of variable entry
"""
function get_end_of_ofvar(tokens::Vector{Token}, i_start::Int64)

    i = i_start
    
    while i > 1
        t = tokens[i]
        if t.type_id == Int64(';')
            return i
        end

        i+=1
    end

    error("No end of var found")
end


"""
    find_closing(tokens::Vector{Token}, i_start::Int64, 
                                        tid_opening::Int64)::Int64

find matching closing bracket position in list of tokens (tokens)
"""
function find_closing(tokens::Vector{Token}, i_start::Int64,
                                         tid_opening::Int64)::Int64

    i = i_start
    n_open = 1
    tid_closing = get_closing(tid_opening)

    while (n_open > 0 || i > length(tokens))
        
        i += 1
        t = tokens[i]
        
        if t.type_id == tid_opening
            n_open += 1
        elseif t.type_id == tid_closing
            n_open -= 1
        end
    end

    if (i > length(tokens))
        error("End of token not found")
    end
    
    return i
end


"""
    check_correct_arr_list!(arr_entries::Vector{PreParsedEntity}

checks if array and list pre parsed types contain same entity types, applies 
    correction for floating and int point numbers ...
"""
function check_correct_arr_list!(arr_entries::Vector{PreParsedEntity})

    for i =1:length(arr_entries)
        arr_ent = arr_entries[i]
        if typeof(arr_ent) != typeof(arr_entries[1])

            if (typeof(arr_ent) == PreParsedINum 
                 && typeof(arr_entries[1]) == PreParsedFNum) 

                 arr_entries[i] = PreParsedFNum(arr_entries[i].string)

            elseif (typeof(arr_ent) == PreParsedFNum 
                 && typeof(arr_entries[1]) == PreParsedINum) 
                
                 arr_entries[1] = PreParsedFNum(arr_entries[1].string)
            else
                error("array/list entries musst be of same type")
            end
            
        end
    end

    return true
end
