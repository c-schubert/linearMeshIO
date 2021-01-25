#= 
Tokenize openfoam polymesh dictionary
    - Currently only implemented for ascii files

TODO: Implement function converting binary and gz files to Vector{Token}
=#

const TokenTypeID_Dict = Dict(
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
        
const TokenSymbol_Dict = Dict(value => key for (key, value) in TokenTypeID_Dict)
    
struct Token
    type_id::Int64 # see TokenTypeID_Dict
    string::String
end

mutable struct Lexer
    buffer::String
    pos::Int64
    Lexer(buffer::String) = new(buffer, 1)
end


#= ---------------------- =#
#= Lexer iterator methods =#
#= ---------------------- =#

"""
    start!(lex::Lexer) 

reset postion of lexer to 1 
"""
function start!(lex::Lexer) 
    lex.pos = 1
end

done(lex::Lexer) = length(lex.buffer) < lex.pos
iteratorsize(lex::Lexer) =  Base.SizeUnknown()


"""
    next_ascii!(lex::Lexer)

divide lexer into tokens -> return next token and set lex.pos after token
"""
function next_ascii!(lex::Lexer)

    if done(lex)
        return (Token(TokenTypeID_Dict[:eof], ""), lex.pos)
    end

    ch = lex.buffer[lex.pos]

    # while empty space skip forward to next possible token
    while ch in " \t\n"
        lex.pos += 1
        if done(lex)
            return Token(TokenTypeID_Dict[:eof], "")
        end
        ch = lex.buffer[lex.pos]
    end

    if in(ch, "/")
        # Looking for comments
        if lex.buffer[lex.pos+1] == '/' # line comment
            spos = lex.pos + 2
            npos = findnext("//", lex.buffer,spos)
            lex.pos =  last(npos) + 1
            return Token(TokenTypeID_Dict[:comment], 
                                lex.buffer[spos:(first(npos)-1)])

        elseif lex.buffer[lex.pos+1] == '*' # multi line comment
            spos = lex.pos + 2
            npos = findnext("*/", lex.buffer, spos)
            lex.pos =  last(npos) + 1
            return Token(TokenTypeID_Dict[:comment], 
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
        return Token(TokenTypeID_Dict[:string], lex.buffer[spos : (first(npos)-1)])
    elseif  in(ch, "+-/*{}();\\:=,|.<>")
          # Looking for general syntax tokens
          lex.pos += 1
          return Token(Int(ch), string(ch))

    elseif isdigit(ch) || ch == '-' 
        # numbers musst start with digit or - no support for .1 etc ...
        #looking for numbers
        # range = findnext(r"\d+", lex.buffer, lex.pos)
        # lex.pos =  last(range) + 1
        # return Token(TokenTypeID_Dict[:number], lex.buffer[range])  
        return tokenize_ascii_number!(lex)
    elseif isletter(ch)
        # looking for word
        range = findnext(r"\w+", lex.buffer, lex.pos)
        lex.pos =  last(range) + 1
        return Token(TokenTypeID_Dict[:word], lex.buffer[range])

    else
        error("Unknown character '$ch' at position: $(lex.pos)")
    end
end


"""
    tokenize_ascii_number!(lex::Lexer)

find strings that represent numbers and return token, also set lex.pos after 
number string
"""
function tokenize_ascii_number!(lex::Lexer)
    regexstr = r"[+\-]?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+\-]?\d+)?"

    range = findnext(regexstr, lex.buffer, lex.pos)

    if (!isempty(range) && first(range) == lex.pos)

        lex.pos = last(range) + 1

        if (contains(lex.buffer[range], '.') || 
            contains(lex.buffer[range], 'E') || 
            contains(lex.buffer[range], 'e') )

            return Token(TokenTypeID_Dict[:float_number], lex.buffer[range])
        else
            return Token(TokenTypeID_Dict[:int_number], lex.buffer[range])
        end
    
    else
        lex.pos += 1
        return Token(Int(lex.buffer[lex.pos]), lex.buffer[range])
    end
end

#= -------------------------- =#
#= End lexer iterator methods =#
#= -------------------------- =#


"""
    tokenize_ascii(lex::Lexer)

tokenize of lexer (buffer)
"""
function tokenize_ascii(lex::Lexer)
    tokens = Vector{Token}(undef,0)
    start!(lex) # just to be shure lex.pos = 1

    while true
        token = next_ascii!(lex)

        push!(tokens, token)

        if token.type_id == TokenTypeID_Dict[:eof]
            break
        end
    end

    return tokens
end


"""
    tokenize_ofmeshfile(filename::String)

tokenize openfoam (ascii) dictionary (filename) from lex buffer
"""
function tokenize_ascii_ofmeshfile(filename::String)
    file = open(filename,"r")
    lexer = Lexer(read(file, String))
    close(file)

    tokens = tokenize_ascii(lexer)
    remove_comments!(tokens)
end


"""
    remove_comments!(tokens::Vector{Token}) 

remove comments from tokens
"""
function remove_comments!(tokens::Vector{Token})
    filter!(t->t.type_id != TokenTypeID_Dict[:comment], tokens)
end


"""
    printtokens(tokens::Vector{Token})

simple printing of tokens
"""
function printtokens(tokens::Vector{Token})
    for (i,t) in enumerate(tokens)
        println(i," ",TokenSymbol_Dict[t.type_id], " \n\t\t: ", t.string, " \n")
    end
end
