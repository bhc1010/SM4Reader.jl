#
#
#
#
#
#
#
#


"""
    fread(io::IO, nb::Int, type::T) where T <: DataType
Reads nb number of bytes from io stream and returns the binary data formatted to the type given. 
type must be a DataType, as indicated from the subtype expression 'where T <: DataType'
"""
function fread(io::IO, nb::Number, type::T) where T <: DataType
    buffer = Vector{UInt8}(undef, Int(nb * sizeof(type)))
    readbytes!(io, buffer)

    if type == Char 
        out = Char.(buffer) |> join
    else
        out = reinterpret(type, buffer)[1]
    end

    out
end

function fread_to_array(io::IO, dims::Int, type::T) where T <: DataType
    img = Array{type}(undef, dims)
    read!(io, img)
end

"""

"""
function fread!(io::IO, out, nb::Int, type::T) where T <: DataType
    if out isa Vector2
        out.x = fread(io, nb, type)
        out.y = fread(io, nb, type)
        return out
    end

    if out isa Vector3
        fread!(io, out.x, nb, type)
        fread!(io, out.y, nb, type)
        fread!(io, out.y, nb, type)
    end

    buffer = Vector{UInt8}(undef, nb * sizeof(type))
    readbytes!(io, buffer)

    if out isa String 
        out = collect(Char, buffer) |> join
    else
        out = reinterpret(type, buffer)[1]
    end
end

"""

"""
function skip!(io::IO, nb::Int, type::T) where T
    skip(io, nb * sizeof(type))
end