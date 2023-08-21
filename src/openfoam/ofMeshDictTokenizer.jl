#= 
Tokenize openfoam polymesh dictionary
    - Currently only implemented for ascii files

TODO: Implement function converting binary and gz files to Vector{Token}
=#

const TokenTypeID_OF_ASCII = Dict(
    :eof => 0,
    :emptyspace => 1,
    :newline => 2,
    :string => 3,
    :word => 4, 
    :int_number => 5,
    :float_number => 6, 
    :comment => 7,
    :bar => Int64('|'),
    :bracket_close => Int64(')'),
    :bracket_open => Int64('('),
    :colon => Int64(':'),
    :comma => Int64(','),
    :curly_brace_close => Int64('}'),
    :curly_brace_open => Int64('{'),
    :dot => Int64('.'),
    :doublequote => Int64('"'),
    :equal => Int64('='),
    :greater => Int64('>'),
    :minus => Int64('-'),
    :plus => Int64('+'),
    :semicolon => Int64(';'),
    :slash_bw => Int64('\\'),
    :slash_fw => Int64('/'),
    :smaller => Int64('<'),
    :star => Int64('*'),
   )
        
const TokenSymbol_Dict = Dict(value => key for (key, value) in TokenTypeID_OF_ASCII)


"""
    next_ascii!(lex::Lexer)

divide lexer into tokens -> return next token and set lex.pos after token
"""
function next_of_dict_ascii!(lex::ASCII_Lexer, symbol_to_tokenID_dict::Dict{Symbol,Int64})

    if done(lex)
        return Token(symbol_to_tokenID_dict[:eof], "")
    end

    ch = lex.buffer[lex.pos]

    # while empty space skip forward to next possible token
    while ch in " \t\n"
        lex.pos += 1
        if done(lex)
            return Token(symbol_to_tokenID_dict[:eof], "")
        end
        ch = lex.buffer[lex.pos]
    end

    if in(ch, "/")
        # Looking for comments
        if lex.buffer[lex.pos+1] == '/' # line comment
            spos = lex.pos + 2
            npos = findnext("//", lex.buffer,spos)
            lex.pos =  last(npos) + 1
            return Token(symbol_to_tokenID_dict[:comment], 
                                lex.buffer[spos:(first(npos)-1)])

        elseif lex.buffer[lex.pos+1] == '*' # multi line comment
            spos = lex.pos + 2
            npos = findnext("*/", lex.buffer, spos)
            lex.pos =  last(npos) + 1
            return Token(symbol_to_tokenID_dict[:comment], 
                                lex.buffer[spos:(first(npos)-1)])

        end

        lex.pos += 1
        return Token(Int(ch), string(ch))
    end

    if ch == '"'
        # looking for quoted strings
        spos = lex.pos + 1
        npos = findnext('"', lex.buffer, spos) # TODO: Does not handle escaped quotes
        lex.pos =  npos + 1
        return Token(symbol_to_tokenID_dict[:string], lex.buffer[spos : (first(npos)-1)])
    elseif  in(ch, "+-/*{}();\\:=,|.<>")
          # Looking for general syntax tokens
          lex.pos += 1
          return Token(Int(ch), string(ch))

    elseif isdigit(ch) || ch == '-' 
        # numbers musst start with digit or - no support for .1 etc ...
        #looking for numbers
        # range = findnext(r"\d+", lex.buffer, lex.pos)
        # lex.pos =  last(range) + 1
        # return Token(symbol_to_tokenID_dict[:number], lex.buffer[range])  
        return tokenize_ascii_number!(lex, symbol_to_tokenID_dict)
    elseif isletter(ch)
        # looking for word
        range = findnext(r"\w+", lex.buffer, lex.pos)
        lex.pos =  last(range) + 1
        return Token(symbol_to_tokenID_dict[:word], lex.buffer[range])

    else
        error("Unknown character '$ch' at position: $(lex.pos)")
    end
end