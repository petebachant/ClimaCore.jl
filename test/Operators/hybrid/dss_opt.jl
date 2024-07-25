using Test, JET
using ClimaComms
using StaticArrays, IntervalSets, LinearAlgebra

import ClimaCore

import ClimaCore:
    ClimaCore,
    slab,
    Domains,
    Meshes,
    Geometry,
    Topologies,
    Spaces,
    Quadratures,
    Fields,
    Operators

import ClimaCore.Utilities: half
import ClimaCore.DataLayouts: level

FT = Float64

vertdomain = Domains.IntervalDomain(
    Geometry.ZPoint{FT}(0.0),
    Geometry.ZPoint{FT}(1.0);
    boundary_names = (:bottom, :top),
)
vertmesh = Meshes.IntervalMesh(vertdomain, nelems = 10)
device = ClimaComms.CPUSingleThreaded()
vert_center_space = Spaces.CenterFiniteDifferenceSpace(device, vertmesh)

horzdomain = Domains.SphereDomain(30.0)
horzmesh = Meshes.EquiangularCubedSphere(horzdomain, 4)
horztopology =
    Topologies.Topology2D(ClimaComms.SingletonCommsContext(device), horzmesh)
quad = Quadratures.GLL{5}()
horzspace = Spaces.SpectralElementSpace2D(horztopology, quad)

hv_center_space =
    Spaces.ExtrudedFiniteDifferenceSpace(horzspace, vert_center_space)

coords = Fields.coordinate_field(hv_center_space)
x = Geometry.UVWVector.(cosd.(coords.lat), 0.0, 0.0)

ww = map(x -> (w = Geometry.Covariant3Vector(x),), ones(hv_center_space))
