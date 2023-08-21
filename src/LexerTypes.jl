
abstract type AbstractLexer end
abstract type AbstractToken end


struct Token <: AbstractToken 
    type_id::Int64 # see TokenTypeID_Dict
    string::String
end

mutable struct ASCII_Lexer <: AbstractLexer
    buffer::String
    pos::Int64

    ASCII_Lexer(buffer::String) = new(buffer, 1)
end
