%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

const DEPOSIT_FACTOR = 3;

@storage_var
func _DVT() -> (address: felt) {
}

@storage_var
func _WETH() -> (address: felt) {
}

@storage_var
func _jediswapPair() -> (address: felt) {
}

@storage_var
func _jediswapFactory() -> (address: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    DVT: felt, WETH: felt, jediswapPair: felt, jediswapFactory: felt
) {
    _DVT.write(DVT);
    _WETH.write(WETH);
    _jediswapPair.write(jediswapPair);
    _jediswapFactory.write(jediswapFactory);

    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                  Internals                                 * //
// * -------------------------------------------------------------------------- * //

func _computeOraclePrice(amount: Uint256) -> (price: Uint256) {
    let (reservesWETH, reservesDVT) = IJediswapFactory.getReserve(
        (_jediswapPair.read()), (_WETH.read()), (_DVT.read())
    );

    let price = IJediswapFactory.quote(Uint256_mul(amount, 10 ** 18), reservesWETH, reservesDVT);

    return (price=price);
}

// * -------------------------------------------------------------------------- * //
// *                                  Externals                                 * //
// * -------------------------------------------------------------------------- * //

@external
func borrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256, recipant: felt
) {
    return ();
}

@external
func calculateDepositRequired{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256
) -> ( {
    return ();
}
