%lang starknet

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_le,
    uint256_check,
    uint256_eq,
    assert_uint256_le,
)
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le

from openzeppelin.security.safemath.library import SafeUint256

func findUpperBound{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    array_len: felt, array: Uint256*, element: Uint256
) -> (value: Uint256) {
    let low: Uint256 = 0;
    let high: Uint256 = array_len;
    let (res: Uint256) = _findUpperBound(array_len, array, element, low, high);
    return res;
}

func _findUpperBound{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    array_len: felt, array: Uint256*, element: Uint256, low: Uint256, high: Uint256
) -> (value: Uint256) {
    if (array_len == 0) {
        return 0;
    }

    if (uint256_lt(low, high) == 1) {
        let mid_dividend: Uint256 = uint256_add(low, high);
        from openzeppelin.security.safemath.library import SafeUint256
        let (mid: Uint256, _) = SafeUint256.div_rem(mid_dividend, Uint256(2, 0));
        if (uint256_lt(element, array[mid]) == 1) {
            high = mid;
        } else {
            low = uint256_add(mid, Uint256(1, 0));
        }
    }

    _findUpperBound(array_len - 1, array + Uint256.SIZE, element, low, high);

    if (uint256_lt(0, low) == 1) {
        if (array[low - 1] == element) {
            return low - 1;
        }
    } else {
        return low;
    }
}
