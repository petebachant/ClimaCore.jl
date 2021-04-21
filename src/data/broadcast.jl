# Broadcasting of AbstractData objects
# https://docs.julialang.org/en/v1/manual/interfaces/#Broadcast-Styles

abstract type DataStyle <: Base.BroadcastStyle end

abstract type DataColumnStyle <: DataStyle end


abstract type DataSlabStyle{Nij} <: DataStyle end

# determine the parent type underlying any SubArrays
parent_array_type(::Type{A}) where {A <: AbstractArray} = A
parent_array_type(::Type{S}) where {S <: SubArray{T, N, A}} where {T, N, A} =
    parent_array_type(A)

struct IJFStyle{Nij, A} <: DataSlabStyle{Nij} end
DataStyle(::Type{IJF{S, Nij, A}}) where {S, Nij, A} =
    IJFStyle{Nij, parent_array_type(A)}()

abstract type Data2DStyle{Nij} <: DataStyle end
struct IJFHStyle{Nij, A} <: Data2DStyle{Nij} end
DataStyle(::Type{IJFH{S, Nij, A}}) where {S, Nij, A} =
    IJFHStyle{Nij, parent_array_type(A)}()

abstract type Data3DStyle <: DataStyle end


Base.Broadcast.BroadcastStyle(::Type{D}) where {D <: AbstractData} =
    DataStyle(D)

# precedence rules
# scalars are broadcast over the data object
Base.Broadcast.BroadcastStyle(
    a::Base.Broadcast.AbstractArrayStyle{0},
    b::DataStyle,
) = b


Base.Broadcast.broadcastable(data::AbstractData) = data

function slab(
    bc::Base.Broadcast.Broadcasted{DS},
    inds...,
) where {Nij, DS <: Data2DStyle{Nij}}
    args = map(arg -> arg isa AbstractData ? slab(arg, inds...) : arg, bc.args)
    axes = (SOneTo(Nij), SOneTo(Nij))
    Base.Broadcast.Broadcasted{DataSlabStyle{DS}}(bc.f, args, axes)
end

function Base.similar(
    bc::Broadcast.Broadcasted{IJFHStyle{Nij, A}},
    ::Type{Eltype},
) where {Nij, A, Eltype}
    Nh = length(bc)
    array = similar(A, (Nij, Nij, typesize(eltype(A), Eltype), Nh))
    return IJFH{Eltype, Nij}(array)
end

function Base.copyto!(
    dest::IJFH{S, Nij},
    bc::Base.Broadcast.Broadcasted{IJFHStyle{Nij, A}},
) where {S, Nij, A}
    nh = length(dest)
    for h in 1:nh
        slab_dest = slab(dest, h)
        slab_bc = slab(bc, h)
        @inbounds for j in 1:Nij, i in 1:Nij
            slab_dest[i, j] = convert(S, slab_bc[i, j])
        end
    end
    return dest
end

# broadcasting scalar assignment
@inline function Base.Broadcast.materialize!(
    ::DS,
    dest,
    bc::Base.Broadcast.Broadcasted{Style},
) where {DS <: DataStyle, Style}
    return copyto!(
        dest,
        Base.Broadcast.instantiate(
            Base.Broadcast.Broadcasted{DS}(bc.f, bc.args, axes(dest)),
        ),
    )
end
