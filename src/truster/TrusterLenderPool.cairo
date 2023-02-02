%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, assert_uint256_le
from starkware.starknet.common.syscalls import call_contract, get_contract_address

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.token.erc20.IERC20 import IERC20

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

@storage_var
func _token() -> (res: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) {
    _token.write(token);
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
    selector: felt,
    calldata_len: felt,
    calldata: felt*,
) -> (success: felt) {
    ReentrancyGuard.start();

    let (pool_address) = get_contract_address();
    let (token) = _token.read();

    let balance_before: Uint256 = IERC20.balanceOf(token, pool_address);

    IERC20.transfer(token, borrower, amount);
    let results = call_contract(
        contract_address=target,
        function_selector=selector,
        calldata_size=calldata_len,
        calldata=calldata,
    );

    let balance_after: Uint256 = IERC20.balanceOf(token, pool_address);
    assert_uint256_le(balance_before, balance_after);

    ReentrancyGuard.end();

    return (success=1);
}
