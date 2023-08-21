#= 
Tokenize COMSOL multiphysicsmesh files
    - Currently only implemented for ascii files mphtxt

=#
const TokenTypeIDs_COMSOL_mphtxt = Dict(
    :eof => 0,
    :emptyspace => 1,
    :newline => 2,
    :string => 3,
    :int_number => 4,
    :float_number => 5, 
    :comment => 6,
   )
    
const TokenIDtoSymbol_COMSOL_mphtxt  = Dict(value => key for (key, value) in TokenTypeIDs_COMSOL_mphtxt)

#= ------------------------------- =#
#= Custom Lexer iterator methods =#
#= ------------------------------- =#

"""
    next_ascii!(lex::Lexer)

divide lexer into tokens -> return next token and set lex.pos after token
"""
function next_ascii_comsol_mphtxt!(lex::ASCII_Lexer, 
            symbol_to_tokenID_dict::Dict{Symbol,Int64})

    if done(lex)
        return Token(symbol_to_tokenID_dict[:eof], "")
    end

    ch = lex.buffer[lex.pos]

    # while empty space skip forward to next possible token
    while ch in " \t\r"
        lex.pos += 1
        if done(lex)
            return Token(symbol_to_tokenID_dict[:eof], "")
        end
        ch = lex.buffer[lex.pos]
    end

    if ch == '\n'
        lex.pos += 1
        return Token(symbol_to_tokenID_dict[:newline], "")
    end

    if in(ch, "#")
        spos = lex.pos + 1
        npos = findnext("\r", lex.buffer,spos)
        lex.pos =  last(npos) + 1
        return Token(symbol_to_tokenID_dict[:comment], 
                            lex.buffer[spos:(first(npos)-1)])
    end

    if isdigit(ch) || ch == '-' 
        # numbers musst start with digit or - no support for .1 etc ...
        #looking for numbers
        # range = findnext(r"\d+", lex.buffer, lex.pos)
        # lex.pos =  last(range) + 1
        # return Token(TokenTypeID_Dict[:number], lex.buffer[range])  
        return tokenize_ascii_number!(lex, symbol_to_tokenID_dict)
    elseif isletter(ch) || ch == '&' || ch == '.'
        # looking for string
        range = findnext(r"\w+", lex.buffer, lex.pos)
        lex.pos =  last(range) + 1
        return Token(symbol_to_tokenID_dict[:string], lex.buffer[range])
    else
        error("Unknown character $(Int(ch)) at position: $(lex.pos)")
        return nothing
    end
end

#= -------------------------- =#
#= End lexer iterator methods =#
#= -------------------------- =#
