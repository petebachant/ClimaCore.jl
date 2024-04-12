if !(@isdefined(test_field_broadcast))
    include("test_non_scalar_utils.jl")
end

test_field_broadcast(;
    test_name = "matrix of covectors times matrix of vectors times matrix \
                 of numbers times matrix of covectors times matrix of \
                 vectors",
    get_result = () ->
        (@. ᶜᶠmat_AC1 ⋅ ᶠᶜmat_C12 ⋅ ᶜᶠmat ⋅ ᶠᶜmat_AC1 ⋅ ᶜᶠmat_C12),
    set_result! = result ->
        (@. result = ᶜᶠmat_AC1 ⋅ ᶠᶜmat_C12 ⋅ ᶜᶠmat ⋅ ᶠᶜmat_AC1 ⋅ ᶜᶠmat_C12),
    ref_set_result! = result -> (@. result =
        ᶜᶠmat ⋅ (
            DiagonalMatrixRow(ᶠlg.gⁱʲ.components.data.:1) ⋅ ᶠᶜmat2 +
            DiagonalMatrixRow(ᶠlg.gⁱʲ.components.data.:2) ⋅ ᶠᶜmat3
        ) ⋅ ᶜᶠmat ⋅ ᶠᶜmat ⋅ (
            DiagonalMatrixRow(ᶜlg.gⁱʲ.components.data.:1) ⋅ ᶜᶠmat2 +
            DiagonalMatrixRow(ᶜlg.gⁱʲ.components.data.:2) ⋅ ᶜᶠmat3
        )),
)
