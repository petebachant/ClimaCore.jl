if !(@isdefined(test_field_broadcast_against_array_reference))
    include("test_scalar_utils.jl")
end

test_field_broadcast_against_array_reference(;
    test_name = "diagonal matrix times bi-diagonal matrix times \
                 tri-diagonal matrix times quad-diagonal matrix times \
                 vector",
    get_result = () -> (@. ᶜᶜmat ⋅ ᶜᶠmat ⋅ ᶠᶠmat ⋅ ᶠᶜmat ⋅ ᶜvec),
    set_result! = result -> (@. result = ᶜᶜmat ⋅ ᶜᶠmat ⋅ ᶠᶠmat ⋅ ᶠᶜmat ⋅ ᶜvec),
    input_fields = (ᶜᶜmat, ᶜᶠmat, ᶠᶠmat, ᶠᶜmat, ᶜvec),
    get_temp_value_fields = () -> (
        (@. ᶜᶜmat ⋅ ᶜᶠmat),
        (@. ᶜᶜmat ⋅ ᶜᶠmat ⋅ ᶠᶠmat),
        (@. ᶜᶜmat ⋅ ᶜᶠmat ⋅ ᶠᶠmat ⋅ ᶠᶜmat),
    ),
    ref_set_result! = (
        _result,
        _ᶜᶜmat,
        _ᶜᶠmat,
        _ᶠᶠmat,
        _ᶠᶜmat,
        _ᶜvec,
        _temp1,
        _temp2,
        _temp3,
    ) -> begin
        mul!(_temp1, _ᶜᶜmat, _ᶜᶠmat)
        mul!(_temp2, _temp1, _ᶠᶠmat)
        mul!(_temp3, _temp2, _ᶠᶜmat)
        mul!(_result, _temp3, _ᶜvec)
    end,
)
