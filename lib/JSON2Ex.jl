module JSON2Ex
using JSON2

function JSON2.write(io::IO, obj::AbstractString; kwargs...)
    if startswith(obj, "{\"type\":") || startswith(obj, "{\"coordinates\":")
        Base.write(io, obj)
    else
        Base.write(io, '"')
        if JSON2.needescape(obj)
            bytes = codeunits(obj)
            for i = 1:length(bytes)
                @inbounds b = JSON2.ESCAPECHARS[bytes[i] + 0x01]
                Base.write(io, b)
            end
        else
            Base.write(io, obj)
        end
        Base.write(io, '"')
    end
    return
end

end

