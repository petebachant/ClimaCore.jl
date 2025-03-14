"""
    interpolate_slab!(output_array, field, slab_indices, weights)

Interpolate horizontal field on the given `slab_indices` using the given interpolation
`weights`.

`interpolate_slab!` interpolates several values at a fixed `z` coordinate. For this reason,
it requires several slab indices and weights.

"""
interpolate_slab!(output_array, field::Fields.Field, slab_indices, weights) =
    interpolate_slab!(
        output_array,
        field::Fields.Field,
        slab_indices,
        weights,
        ClimaComms.device(field),
    )


# CPU kernel for 3D configurations
function interpolate_slab!(
    output_array,
    field::Fields.Field,
    slab_indices,
    weights::AbstractArray{Tuple{A, A}},
    device::ClimaComms.AbstractCPUDevice,
) where {A}
    space = axes(field)
    FT = Spaces.undertype(space)

    for index in 1:length(output_array)
        (I1, I2) = weights[index]
        Nq1, Nq2 = length(I1), length(I2)

        output_array[index] = zero(FT)

        for j in 1:Nq2, i in 1:Nq1
            ij = CartesianIndex((i, j))
            output_array[index] +=
                I1[i] *
                I2[j] *
                Operators.get_node(space, field, ij, slab_indices[index])
        end
    end
end

# CPU kernel for 2D configurations
function interpolate_slab!(
    output_array,
    field::Fields.Field,
    slab_indices,
    weights::AbstractArray{Tuple{A}},
    device::ClimaComms.AbstractCPUDevice,
) where {A}
    space = axes(field)
    FT = Spaces.undertype(space)

    for index in 1:length(output_array)
        (I1,) = weights[index]
        Nq = length(I1)

        output_array[index] = zero(FT)

        for i in 1:Nq
            ij = CartesianIndex((i,))
            output_array[index] +=
                I1[i] *
                Operators.get_node(space, field, ij, slab_indices[index])
        end
    end
end

"""
    vertical_indices_ref_coordinate(space, zcoord)

Return the vertical indices of the elements below and above `zcoord`.

Return also the correct reference coordinate `zcoord` for vertical interpolation.
"""
function vertical_indices_ref_coordinate end

function vertical_indices_ref_coordinate(
    space::Spaces.FaceExtrudedFiniteDifferenceSpace,
    zcoord,
)
    vert_topology = Spaces.vertical_topology(space)
    vert_mesh = vert_topology.mesh

    velem = Meshes.containing_element(vert_mesh, zcoord)
    ξ3, = Meshes.reference_coordinates(vert_mesh, velem, zcoord)
    v_lo, v_hi = velem - half, velem + half
    return v_lo, v_hi, ξ3
end

function vertical_indices_ref_coordinate(
    space::Spaces.CenterExtrudedFiniteDifferenceSpace,
    zcoord,
)
    vert_topology = Spaces.vertical_topology(space)
    vert_mesh = vert_topology.mesh
    Nz = Spaces.nlevels(space)

    velem = Meshes.containing_element(vert_mesh, zcoord)
    ξ3, = Meshes.reference_coordinates(vert_mesh, velem, zcoord)
    if ξ3 < 0
        if Topologies.isperiodic(Spaces.vertical_topology(space))
            v_lo = mod1(velem - 1, Nz)
        else
            v_lo = max(velem - 1, 1)
        end
        v_hi = velem
        ξ3 = ξ3 + 1
    else
        v_lo = velem
        if Topologies.isperiodic(Spaces.vertical_topology(space))
            v_hi = mod1(velem + 1, Nz)
        else
            v_hi = min(velem + 1, Nz)
        end
        ξ3 = ξ3 - 1
    end
    return v_lo, v_hi, ξ3
end

"""
    interpolate_slab_level(
                           field::Fields.Field,
                           h::Integer,
                           Is::Tuple,
                           zpts;
                           fill_value = eltype(field)(NaN)
                           )

Vertically interpolate the given `field` on `zpts`.

`interpolate_slab_level!` interpolates several values at a fixed horizontal coordinate.

The field is linearly interpolated across two neighboring vertical elements.

For centered-valued fields, if `zcoord` is in the top (bottom) half of a top (bottom)
element in a column, no interpolation is performed and the value at the cell center is
returned. Effectively, this means that the interpolation is first-order accurate across the
column, but zeroth-order accurate close to the boundaries.

Return `fill_value` when the vertical coordinate is negative.

"""
function interpolate_slab_level!(
    output_array,
    field::Fields.Field,
    h::Integer,
    Is::Tuple,
    vertical_indices_ref_coordinates,
)
    device = ClimaComms.device(field)

    interpolate_slab_level!(
        output_array,
        field,
        vertical_indices_ref_coordinates,
        h,
        Is,
        device,
    )
end

# CPU kernel for 3D configurations
function interpolate_slab_level!(
    output_array,
    field::Fields.Field,
    vidx_ref_coordinates,
    h::Integer,
    (I1, I2)::Tuple{<:AbstractArray, <:AbstractArray},
    device::ClimaComms.AbstractCPUDevice,
)
    space = axes(field)
    FT = Spaces.undertype(space)
    Nq1, Nq2 = length(I1), length(I2)

    for index in 1:length(vidx_ref_coordinates)
        v_lo, v_hi, ξ3 = vidx_ref_coordinates[index]

        f_lo = zero(FT)
        f_hi = zero(FT)

        for j in 1:Nq2, i in 1:Nq1
            ij = CartesianIndex((i, j))
            f_lo +=
                I1[i] *
                I2[j] *
                Operators.get_node(space, field, ij, Fields.SlabIndex(v_lo, h))
            f_hi +=
                I1[i] *
                I2[j] *
                Operators.get_node(space, field, ij, Fields.SlabIndex(v_hi, h))
        end

        output_array[index] = ((1 - ξ3) * f_lo + (1 + ξ3) * f_hi) / 2
    end
end

# CPU kernel for 2D configurations
function interpolate_slab_level!(
    output_array,
    field::Fields.Field,
    vidx_ref_coordinates,
    h::Integer,
    (I1,)::Tuple{<:AbstractArray},
    device::ClimaComms.AbstractCPUDevice,
)
    space = axes(field)
    FT = Spaces.undertype(space)
    Nq = length(I1)

    for index in 1:length(vidx_ref_coordinates)
        v_lo, v_hi, ξ3 = vidx_ref_coordinates[index]

        f_lo = zero(FT)
        f_hi = zero(FT)

        for i in 1:Nq
            ij = CartesianIndex((i,))
            f_lo +=
                I1[i] *
                Operators.get_node(space, field, ij, Fields.SlabIndex(v_lo, h))
            f_hi +=
                I1[i] *
                Operators.get_node(space, field, ij, Fields.SlabIndex(v_hi, h))
        end
        output_array[index] = ((1 - ξ3) * f_lo + (1 + ξ3) * f_hi) / 2
    end
end

"""
    interpolate_array(field, xpts, ypts)
    interpolate_array(field, xpts, ypts, zpts)

Interpolate a field to a regular array using pointwise interpolation.

This is primarily used for plotting and diagnostics.

# Examples

```julia
longpts = range(Geometry.LongPoint(-180.0), Geometry.LongPoint(180.0), length = 21)
latpts = range(Geometry.LatPoint(-80.0), Geometry.LatPoint(80.0), length = 21)
zpts = range(Geometry.ZPoint(0.0), Geometry.ZPoint(1000.0), length = 21)

interpolate_array(field, longpts, latpts, zpts)
```

!!! note
    Hypsography is not currently handled correctly.
"""
function interpolate_array end

function interpolate_array(
    field::Fields.ExtrudedFiniteDifferenceField,
    xpts,
    zpts,
)
    space = axes(field)
    @assert ClimaComms.context(space) isa ClimaComms.SingletonCommsContext

    horz_topology = Spaces.topology(space)
    horz_mesh = horz_topology.mesh

    T = eltype(field)
    array = zeros(T, length(xpts), length(zpts))

    FT = Spaces.undertype(space)

    vertical_indices_ref_coordinates =
        [vertical_indices_ref_coordinate(space, zcoord) for zcoord in zpts]

    for (ix, xcoord) in enumerate(xpts)
        hcoord = xcoord
        helem = Meshes.containing_element(horz_mesh, hcoord)
        quad = Spaces.quadrature_style(space)
        quad_points, _ = Quadratures.quadrature_points(FT, quad)
        weights = interpolation_weights(horz_mesh, hcoord, quad_points)
        h = helem

        interpolate_slab_level!(
            view(array, ix, :),
            field,
            h,
            weights,
            vertical_indices_ref_coordinates,
        )
    end
    return array
end

function interpolate_array(
    field::Fields.ExtrudedFiniteDifferenceField,
    xpts,
    ypts,
    zpts,
)
    space = axes(field)
    @assert ClimaComms.context(space) isa ClimaComms.SingletonCommsContext

    horz_topology = Spaces.topology(space)
    horz_mesh = horz_topology.mesh

    T = eltype(field)
    array = zeros(T, length(xpts), length(ypts), length(zpts))

    FT = Spaces.undertype(space)

    vertical_indices_ref_coordinates =
        [vertical_indices_ref_coordinate(space, zcoord) for zcoord in zpts]

    for (iy, ycoord) in enumerate(ypts), (ix, xcoord) in enumerate(xpts)
        hcoord = Geometry.product_coordinates(xcoord, ycoord)
        helem = Meshes.containing_element(horz_mesh, hcoord)
        quad = Spaces.quadrature_style(space)
        quad_points, _ = Quadratures.quadrature_points(FT, quad)
        weights = interpolation_weights(horz_mesh, hcoord, quad_points)
        gidx = horz_topology.orderindex[helem]
        h = gidx

        interpolate_slab_level!(
            view(array, ix, iy, :),
            field,
            h,
            weights,
            vertical_indices_ref_coordinates,
        )
    end
    return array
end

"""
    interpolation_weights(horz_mesh, hcoord, quad_points)

Return the weights (tuple of arrays) to interpolate fields onto `hcoord` on the
given mesh and quadrature points.
"""
function interpolation_weights end

function interpolation_weights(
    horz_mesh::Meshes.AbstractMesh2D,
    hcoord,
    quad_points,
)
    helem = Meshes.containing_element(horz_mesh, hcoord)
    ξ1, ξ2 = Meshes.reference_coordinates(horz_mesh, helem, hcoord)
    WI1 = Quadratures.interpolation_matrix(SVector(ξ1), quad_points)
    WI2 = Quadratures.interpolation_matrix(SVector(ξ2), quad_points)
    return (WI1, WI2)
end

function interpolation_weights(
    horz_mesh::Meshes.AbstractMesh1D,
    hcoord,
    quad_points,
)
    helem = Meshes.containing_element(horz_mesh, hcoord)
    ξ1, = Meshes.reference_coordinates(horz_mesh, helem, hcoord)
    WI1 = Quadratures.interpolation_matrix(SVector(ξ1), quad_points)
    return (WI1,)
end
