%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import call_contract

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

@storage_var
func token() -> (token: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token: felt
) {
    token.write(_token);
    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                  Externals                                 * //
// * -------------------------------------------------------------------------- * //

@external
func flashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256, 
    borrower: felt,
    target: felt,
    calldata: Call*
) {
    //! TODO: implement trusted flash loan
    return ();
}
