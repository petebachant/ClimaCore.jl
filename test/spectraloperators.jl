using Test
using StaticArrays
import ClimaCore.DataLayouts: IJFH, VF
import ClimaCore:
    Geometry, Fields, Domains, Topologies, Meshes, Spaces, Operators
using LinearAlgebra, IntervalSets


domain = Domains.RectangleDomain(
    -pi..pi,
    -pi..pi;
    x1periodic = true,
    x2periodic = true,
)
mesh = Meshes.EquispacedRectangleMesh(domain, 16, 16)
grid_topology = Topologies.GridTopology(mesh)

Nq = 5
quad = Spaces.Quadratures.GLL{Nq}()

space = Spaces.SpectralElementSpace2D(grid_topology, quad)

coords = Fields.coordinate_field(space)

@testset "gradient" begin
    f = sin.(coords.x1 .+ 2 .* coords.x2)

    grad = Operators.Gradient()
    gradf = grad.(f)
    Spaces.weighted_dss!(gradf)

    @test gradf ≈
          Geometry.Cartesian12Vector.(
        cos.(coords.x1 .+ 2 .* coords.x2),
        2 .* cos.(coords.x1 .+ 2 .* coords.x2),
    ) rtol = 1e-2
end


@testset "weak gradient" begin
    f = sin.(coords.x1 .+ 2 .* coords.x2)

    wgrad = Operators.WeakGradient()
    gradf = wgrad.(f)
    Spaces.weighted_dss!(gradf)

    @test gradf ≈
          Geometry.Cartesian12Vector.(
        cos.(coords.x1 .+ 2 .* coords.x2),
        2 .* cos.(coords.x1 .+ 2 .* coords.x2),
    ) rtol = 1e-2
end

@testset "curl" begin
    v =
        Geometry.Cartesian12Vector.(
            sin.(coords.x1 .+ 2 .* coords.x2),
            cos.(3 .* coords.x1 .+ 4 .* coords.x2),
        )

    curl = Operators.Curl()
    curlv = curl.(v)
    Spaces.weighted_dss!(curlv)
    curlv_ref =
        Geometry.Contravariant3Vector.(
            .-3 .* sin.(3 .* coords.x1 .+ 4 .* coords.x2) .-
            2 .* cos.(coords.x1 .+ 2 .* coords.x2),
        )

    @test curlv ≈ curlv_ref rtol = 1e-2
end



@testset "curl-curl" begin
    v =
        Geometry.Cartesian12Vector.(
            sin.(coords.x1 .+ 2 .* coords.x2),
            cos.(3 .* coords.x1 .+ 2 .* coords.x2),
        )
    curlv_ref =
        .-3 .* sin.(3 .* coords.x1 .+ 2 .* coords.x2) .-
        2 .* cos.(coords.x1 .+ 2 .* coords.x2)
    curlcurlv_ref1 =
        .-6 .* cos.(3 .* coords.x1 .+ 2 .* coords.x2) .+
        4 .* sin.(coords.x1 .+ 2 .* coords.x2)
    curlcurlv_ref2 =
        9 .* cos.(3 .* coords.x1 .+ 2 .* coords.x2) .-
        2 .* sin.(coords.x1 .+ 2 .* coords.x2)

    curl = Operators.Curl()
    curlcurlv =
        Geometry.Cartesian12Vector.(curl.(Geometry.Covariant3Vector.(curl.(v))))
    Spaces.weighted_dss!(curlcurlv)

    @test curlcurlv ≈
          Geometry.Cartesian12Vector.(curlcurlv_ref1, curlcurlv_ref2) rtol =
        4e-2
end

@testset "weak curl-strong curl" begin
    v =
        Geometry.Cartesian12Vector.(
            sin.(coords.x1 .+ 2 .* coords.x2),
            cos.(3 .* coords.x1 .+ 2 .* coords.x2),
        )
    curlv_ref =
        .-3 .* sin.(3 .* coords.x1 .+ 2 .* coords.x2) .-
        2 .* cos.(coords.x1 .+ 2 .* coords.x2)
    curlcurlv_ref1 =
        .-6 .* cos.(3 .* coords.x1 .+ 2 .* coords.x2) .+
        4 .* sin.(coords.x1 .+ 2 .* coords.x2)
    curlcurlv_ref2 =
        9 .* cos.(3 .* coords.x1 .+ 2 .* coords.x2) .-
        2 .* sin.(coords.x1 .+ 2 .* coords.x2)

    curl = Operators.Curl()
    wcurl = Operators.WeakCurl()
    curlcurlv =
        Geometry.Cartesian12Vector.(
            wcurl.(Geometry.Covariant3Vector.(curl.(v))),
        )
    Spaces.weighted_dss!(curlcurlv)

    @test curlcurlv ≈
          Geometry.Cartesian12Vector.(curlcurlv_ref1, curlcurlv_ref2) rtol =
        4e-2
end



@testset "weak curl" begin
    v =
        Geometry.Cartesian12Vector.(
            sin.(coords.x1 .+ 2 .* coords.x2),
            cos.(3 .* coords.x1 .+ 4 .* coords.x2),
        )

    wcurl = Operators.WeakCurl()
    curlv = wcurl.(v)
    Spaces.weighted_dss!(curlv)
    curlv_ref =
        .-3 .* sin.(3 .* coords.x1 .+ 4 .* coords.x2) .-
        2 .* cos.(coords.x1 .+ 2 .* coords.x2)

    @test curlv ≈ Geometry.Contravariant3Vector.(curlv_ref) rtol = 1e-2
end

@testset "div" begin
    v =
        Geometry.Cartesian12Vector.(
            sin.(coords.x1 .+ 2 .* coords.x2),
            cos.(3 .* coords.x1 .+ 2 .* coords.x2),
        )

    div = Operators.Divergence()
    divv = div.(v)
    Spaces.weighted_dss!(divv)
    divv_ref =
        cos.(coords.x1 .+ 2 .* coords.x2) .-
        2 .* sin.(3 .* coords.x1 .+ 2 .* coords.x2)

    @test divv ≈ divv_ref rtol = 1e-2
end


@testset "weak div" begin
    v =
        Geometry.Cartesian12Vector.(
            sin.(coords.x1 .+ 2 .* coords.x2),
            cos.(3 .* coords.x1 .+ 2 .* coords.x2),
        )

    wdiv = Operators.WeakDivergence()
    divv = wdiv.(v)
    Spaces.weighted_dss!(divv)
    divv_ref =
        cos.(coords.x1 .+ 2 .* coords.x2) .-
        2 .* sin.(3 .* coords.x1 .+ 2 .* coords.x2)

    @test divv ≈ divv_ref rtol = 1e-2
end


@testset "annhilator property: curl-grad" begin
    f = sin.(coords.x1 .+ 2 .* coords.x2)

    grad = Operators.Gradient()
    gradf = grad.(f)
    Spaces.weighted_dss!(gradf)

    curl = Operators.Curl()
    curlgradf = curl.(gradf)
    Spaces.weighted_dss!(curlgradf)

    @test norm(curlgradf) < 1e-12
end


@testset "annhilator property: div-curl" begin
    v = Geometry.Covariant3Vector.(sin.(coords.x1 .+ 2 .* coords.x2))
    curl = Operators.Curl()
    curlv = curl.(v)
    Spaces.weighted_dss!(curlv)

    div = Operators.Divergence()
    divcurlv = div.(curlv)
    Spaces.weighted_dss!(divcurlv)

    @test norm(divcurlv) < 1e-12
end

@testset "scalar hyperdiffusion" begin
    k = 2
    l = 3
    y = @. sin(k * coords.x1 + l * coords.x2)
    ∇⁴y_ref = @. (k^2 + l^2)^2 * sin(k * coords.x1 + l * coords.x2)

    wdiv = Operators.WeakDivergence()
    grad = Operators.Gradient()
    χ = Spaces.weighted_dss!(@. wdiv(grad(y)))
    ∇⁴y = Spaces.weighted_dss!(@. wdiv(grad(χ)))

    @test ∇⁴y_ref ≈ ∇⁴y rtol = 2e-2
end

@testset "vector hyperdiffusion" begin
    k = 2
    l = 3
    y = @. Geometry.Cartesian12Vector(sin(k * coords.x1 + l * coords.x2), 0.0)
    ∇⁴y_ref = @. Geometry.Cartesian12Vector(
        (k^2 + l^2)^2 * sin(k * coords.x1 + l * coords.x2),
        0.0,
    )

    curl = Operators.Curl()
    wcurl = Operators.WeakCurl()

    sdiv = Operators.Divergence()
    wgrad = Operators.WeakGradient()

    χ = Spaces.weighted_dss!(
        @. wgrad(sdiv(y)) - Geometry.Cartesian12Vector(
            wcurl(Geometry.Covariant3Vector(curl(y))),
        )
    )
    ∇⁴y = Spaces.weighted_dss!(
        @. wgrad(sdiv(χ)) - Geometry.Cartesian12Vector(
            wcurl(Geometry.Covariant3Vector(curl(χ))),
        )
    )

    @test ∇⁴y_ref ≈ ∇⁴y rtol = 2e-2
end
