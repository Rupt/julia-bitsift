_PrimitiveSigned = Union{Int8,Int16,Int32,Int64,Int128}
_PrimitiveUnsigned = Union{UInt8,UInt16,UInt32,UInt64,UInt128}
_PrimitiveInteger = Union{_PrimitiveSigned,_PrimitiveUnsigned}

function encode(key::T)::BitVector where {T<:_PrimitiveInteger}
    length = sizeof(T) * 8
    return BitVector((key >> i) & 1 for i in (length - 1):-1:0)
end

function encode(item::T)::BitVector where {T<:AbstractBitHash}
    return cat((encode(getfield(item, field)) for field in fieldnames(T))...; dims=1)
end

# Linear algebra modulo 2

struct XorMatrix
    column::Vector{UInt64}
end

function xor_mul(left::XorMatrix, vector::UInt64)::UInt64  # L @ v
    @assert length(left.column) == 64
    x::UInt64 = 0
    for i in 0:63
        bit = (vector >> i) & 1
        # In C, we want a branchless `result ^= bit ? col : 0;`.
        x = xor(x, left.column[i + 1] & -bit)
    end
    return x
end

function xor_mul(left::XorMatrix, right::XorMatrix)::XorMatrix  # L @ R
    @assert length(left.column) == length(right.column) == 64
    return XorMatrix([xor_mul(left, col) for col in right.column])
end
