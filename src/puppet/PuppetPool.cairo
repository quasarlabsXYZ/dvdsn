%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

const DEPOSIT_FACTOR = 2;

@storage_var
func DVT() -> (address: felt) {
}

@storage_var
func uniswapPair() -> (address: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _DVT: felt,
    _uniswapPair: felt,
) {
    DVT.write(_DVT);
    uniswapPair.write(_uniswapPair);

    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                  Externals                                 * //
// * -------------------------------------------------------------------------- * //

@external
func borrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256,
    recipant: felt,
) {
    return ();
}

@external
func calculateDepositRequired{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256,
) {
    return ();
}

@external
func _computeOraclePrice() {
    return ();
}