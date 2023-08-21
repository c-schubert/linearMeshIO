
include("LexerTypes.jl")

#= ---------------------- =#
#= Lexer iterator methods =#
#= ---------------------- =#

"""
    start!(lex::Lexer) 

reset postion of lexer to 1 
"""
function start!(lex::AbstractLexer) 
    lex.pos = 1
end

done(lex::AbstractLexer) = length(lex.buffer) < lex.pos
iteratorsize(lex::AbstractLexer) =  Base.SizeUnknown()


#= ----------------------- =#
#= Specific Lexer funtions =#
#= ----------------------- =#

include("./COMSOL/COMSOLmphTokenizer.jl")
include("./openfoam/OfMeshDictTokenizer.jl")

"""
    tokenize_ascii_number!(lex::Lexer)

find strings that represent numbers and return token, also set lex.pos after 
number string
"""
function tokenize_ascii_number!(lex::ASCII_Lexer, symbol_to_tokenID_dict::Dict{Symbol,Int64})
    regexstr = r"[+\-]?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+\-]?\d+)?"

    range = findnext(regexstr, lex.buffer, lex.pos)

    if (!isempty(range) && first(range) == lex.pos)

        lex.pos = last(range) + 1

        if (contains(lex.buffer[range], '.') || 
            contains(lex.buffer[range], 'E') || 
            contains(lex.buffer[range], 'e') )

            return Token(symbol_to_tokenID_dict[:float_number], lex.buffer[range])
        else
            return Token(symbol_to_tokenID_dict[:int_number], lex.buffer[range])
        end
    
    else
        lex.pos += 1
        return Token(Int(lex.buffer[lex.pos]), lex.buffer[range])
    end
end


#= ----------------------- =#
#= Lexer general functions =#
#= ----------------------- =#


"""
    tokenize_ascii(lex::Lexer)

tokenize of lexer (buffer)
"""
function tokenize_ascii(lex::ASCII_Lexer, next_ascii!::Function, 
            symbol_to_tokenID_dict::Dict{Symbol,Int64})

    tokens = Vector{Token}(undef,0)
    start!(lex) # just to be shure lex.pos = 1

    while true
        token = next_ascii!(lex, symbol_to_tokenID_dict) # next ascii defined within file specific subfolders

        push!(tokens, token)

        if token.type_id == symbol_to_tokenID_dict[:eof]
            break
        end
    end

    return tokens
end


"""
    tokenize_ofmeshfile(filename::String)

tokenize openfoam (ascii) dictionary (filename) from lex buffer
"""
function tokenize_ascii_file(filename::String, file_format_desc::String)
    file = open(filename,"r")

    file_format_symb = FileFormatSymbols[file_format_desc]
    lexer = ASCII_Lexer(read(file, String))
    close(file)

    if file_format_symb == :of_ascii
        tokenID_to_symbol_dict = TokenIDtoSymbol_COMSOL_mphtxt
        symbol_to_tokenID_dict = TokenTypeIDs_COMSOL_mphtxt
        tokens = tokenize_ascii(lexer, next_of_dict_ascii!, symbol_to_tokenID_dict)
    elseif file_format_symb == :of_bin
        println("not implemented jet!") 
    elseif file_format_symb == :of_gz
        # gzip and then read
        println("not implemented jet!")
    elseif file_format_symb == :comsol_mphtxt_ascii
        tokenID_to_symbol_dict = TokenIDtoSymbol_COMSOL_mphtxt
        symbol_to_tokenID_dict = TokenTypeIDs_COMSOL_mphtxt
        tokens = tokenize_ascii(lexer, next_ascii_comsol_mphtxt!, symbol_to_tokenID_dict)
    elseif file_format_symb == :ansys_msh_ascii
        println("not implemented jet!")
    else
        error("Undefined file format!")
    end

    # remove_comments!(tokens, symbol_to_tokenID_dict)

    return symbol_to_tokenID_dict, tokenID_to_symbol_dict, tokens
end


"""
    remove_comments!(tokens::Vector{Token}) 

remove comments from tokens
"""
function remove_comments!(tokens::Vector{Token}, symbol_to_tokenID_dict::Dict{Symbol,Int64})
    filter!(t->t.type_id != symbol_to_tokenID_dict[:comment], tokens)
end


"""
    printtokens(tokens::Vector{Token})

simple printing of tokens
"""
function printtokens(tokens::Vector{Token}, tokenID_to_symbol_dict::Dict{Int64,Symbol}; 
            display::Bool=false, to_file::Bool = true, file="debug_tokens.txt")
    if to_file
        io = open(file, "w")
    end

    for (i,t) in enumerate(tokens)
        str = "($(tokenID_to_symbol_dict[t.type_id]), $(t.string))\n"

        if display
            println(i," ", str)
        end

        if to_file
            write(io, str)
        end
    end

    if to_file
        close(io)
    end
end
