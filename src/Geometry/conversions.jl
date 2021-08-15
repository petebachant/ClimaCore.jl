
ContravariantVector(u::ContravariantVector, local_geometry::LocalGeometry) = u
ContravariantVector(u::CartesianVector, local_geometry::LocalGeometry) =
    local_geometry.∂ξ∂x * u
ContravariantVector(u::CovariantVector, local_geometry::LocalGeometry) =
    local_geometry.∂ξ∂x * local_geometry.∂ξ∂x' * u

CovariantVector(u::CovariantVector, local_geometry::LocalGeometry) = u
CovariantVector(u::CartesianVector, local_geometry::LocalGeometry) =
    local_geometry.∂x∂ξ' * u
CovariantVector(u::ContravariantVector, local_geometry::LocalGeometry) =
    local_geometry.∂x∂ξ' * local_geometry.∂x∂ξ * u

CartesianVector(u::CartesianVector, local_geometry::LocalGeometry) = u
CartesianVector(u::CovariantVector, local_geometry::LocalGeometry) =
    local_geometry.∂ξ∂x' * u
CartesianVector(u::ContravariantVector, local_geometry::LocalGeometry) =
    local_geometry.∂x∂ξ * u

# These are for compatibility, and should be removed

Contravariant12Vector(u::ContravariantVector, local_geometry::LocalGeometry) = u
Contravariant12Vector(u::CartesianVector, local_geometry::LocalGeometry) =
    local_geometry.∂ξ∂x * u
Contravariant12Vector(u::CovariantVector, local_geometry::LocalGeometry) =
    local_geometry.∂ξ∂x * local_geometry.∂ξ∂x' * u

Covariant12Vector(u::CovariantVector, local_geometry::LocalGeometry) = u
Covariant12Vector(u::CartesianVector, local_geometry::LocalGeometry) =
    local_geometry.∂x∂ξ' * u
Covariant12Vector(u::ContravariantVector, local_geometry::LocalGeometry) =
    local_geometry.∂x∂ξ' * local_geometry.∂x∂ξ * u

Cartesian12Vector(u::CartesianVector, local_geometry::LocalGeometry) = u
Cartesian12Vector(u::CovariantVector, local_geometry::LocalGeometry) =
    local_geometry.∂ξ∂x' * u
Cartesian12Vector(u::ContravariantVector, local_geometry::LocalGeometry) =
    local_geometry.∂x∂ξ * u


covariant1(u::AxisVector, local_geometry::LocalGeometry) =
    CovariantVector(u, local_geometry).u₁
covariant2(u::AxisVector, local_geometry::LocalGeometry) =
    CovariantVector(u, local_geometry).u₂
covariant3(u::AxisVector, local_geometry::LocalGeometry) =
    CovariantVector(u, local_geometry).u₃

contravariant1(u::AxisVector, local_geometry::LocalGeometry) =
    ContravariantVector(u, local_geometry).u¹
contravariant2(u::AxisVector, local_geometry::LocalGeometry) =
    ContravariantVector(u, local_geometry).u²
contravariant3(u::AxisVector, local_geometry::LocalGeometry) =
    ContravariantVector(u, local_geometry).u³


contravariant1(
    A::Axis2Tensor{<:Any, Tuple{Cartesian12Axis, Cartesian12Axis}},
    local_geometry::LocalGeometry,
) = (local_geometry.∂ξ∂x * A)[1, :]
contravariant2(
    A::Axis2Tensor{<:Any, Tuple{Cartesian12Axis, Cartesian12Axis}},
    local_geometry::LocalGeometry,
) = (local_geometry.∂ξ∂x * A)[2, :]


Covariant3Vector(x::AbstractFloat, ::LocalGeometry) = Covariant3Vector(x)
Contravariant3Vector(x::AbstractFloat, ::LocalGeometry) =
    Contravariant3Vector(x)


# conversions
function Covariant3Vector(
    uⁱ::Contravariant3Vector,
    local_geometry::LocalGeometry,
)
    # Not true generally, but is in 2D
    Covariant3Vector(uⁱ.u³)
end


"""
    divergence_result_type(V)

The return type when taking the divergence of a field of type `V`.

Required for statically infering the result type of the divergence operation for StaticArray.FieldVector subtypes.
"""
divergence_result_type(::Type{V}) where {V <: AxisVector} = eltype(V)
divergence_result_type(
    ::Type{Axis2Tensor{FT, Tuple{A1, A2}, S}},
) where {
    FT,
    A1 <: CartesianAxis,
    A2 <: CartesianAxis,
    S <: StaticMatrix{S1, S2},
} where {S1, S2} = AxisVector{FT, A1, SVector{S1, FT}}

curl_result_type(::Type{V}) where {V <: Covariant12Vector{FT}} where {FT} =
    Contravariant3Vector{FT}
curl_result_type(::Type{V}) where {V <: Cartesian12Vector{FT}} where {FT} =
    Contravariant3Vector{FT}

# not generally true that Contravariant3Vector => Covariant3Vector, but is for our 2D case
# curl of Covariant3Vector -> Contravariant12Vector
curl_result_type(::Type{V}) where {V <: Covariant3Vector{FT}} where {FT} =
    Contravariant12Vector{FT}

_norm_sqr(x, local_geometry) = LinearAlgebra.norm_sqr(x)
function _norm_sqr(u::Contravariant3Vector, local_geometry::LocalGeometry)
    LinearAlgebra.norm_sqr(u.u³)
end
function _norm_sqr(uᵢ::CovariantVector, local_geometry::LocalGeometry)
    LinearAlgebra.norm_sqr(CartesianVector(uᵢ, local_geometry))
end
function _norm_sqr(uᵢ::ContravariantVector, local_geometry::LocalGeometry)
    LinearAlgebra.norm_sqr(CartesianVector(uᵢ, local_geometry))
end

_norm(u::AxisVector, local_geometry) = sqrt(_norm_sqr(u, local_geometry))

_cross(u::AxisVector, v::AxisVector, local_geometry) = LinearAlgebra.cross(
    ContravariantVector(u, local_geometry),
    ContravariantVector(v, local_geometry),
)




#=

function contravariant1(
    A::Tensor{Contravariant12Vector{FT}, V},
    local_geometry::LocalGeometry,
) where {FT, V}
    V(A.matrix[1, :]...)
end
function contravariant2(
    A::Tensor{Contravariant12Vector{FT}, V},
    local_geometry::LocalGeometry,
) where {FT, V}
    V(A.matrix[2, :]...)
end
function contravariant1(
    A::Tensor{Cartesian12Vector{FT}, V},
    local_geometry::LocalGeometry,
) where {FT, V}
    V((local_geometry.∂ξ∂x[1, :]' * A.matrix)...)
end
function contravariant2(
    A::Tensor{Cartesian12Vector{FT}, V},
    local_geometry::LocalGeometry,
) where {FT, V}
    V((local_geometry.∂ξ∂x[2, :]' * A.matrix)...)
end
=#
#=


"""
    SphericalCartesianVector

Representation of a vector in spherical cartesian coordinates.
"""
struct SphericalCartesianVector{FT <: Number}
    "zonal (eastward) component"
    u::FT
    "meridional (northward) component"
    v::FT
    "radial (upward) component"
    w::FT
end


function spherical_cartesian_basis(geom::LocalGeometry)
    x = geom.x

    r12 = hypot(x[2], x[1])
    r = hypot(x[3], r12)

    (
        û = SVector(-x[2] / r12, x[1] / r12, 0),
        v̂ = SVector(
            -(x[3] / r) * (x[1] / r12),
            -(x[3] / r) * (x[2] / r12),
            r12 / r,
        ),
        ŵ = x ./ r,
    )
end

function SphericalCartesianVector(v::CartesianVector, geom::LocalGeometry)
    b = spherical_cartesian_basis(geom)
    SphericalCartesianVector(dot(b.û, v), dot(b.v̂, v), dot(b.ŵ, v))
end

function CartesianVector(s::SphericalCartesianVector, geom::LocalGeometry)
    b = spherical_cartesian_basis(geom)
    return s.u .* b.û .+ s.v .* b.v̂ .+ s.w .* b.ŵ
end

=#
