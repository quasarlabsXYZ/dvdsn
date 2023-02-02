%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.token.erc20.IERC20 import IERC20

from src.unstoppable.interfaces.IUnstoppableLender import IUnstoppableLender


// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

@storage_var
func _owner() -> (res: felt) {
}

@storage_var
func _pool() -> (res: felt) {
}


// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pool: felt
) {
    _pool.write(pool);

    let (caller) = get_caller_address();
    _owner.write(caller);

    return ();
}


// * -------------------------------------------------------------------------- * //
// *                                  Externals                                 * //
// * -------------------------------------------------------------------------- * //

@external
func receiveTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt,
    amount: Uint256
) {
    let (caller) = get_caller_address();
    let (pool) = _pool.read();

    // Sender must be _pool
    assert caller = pool;

    //Return all tokens to the _pool
    IERC20.transfer(token_address, caller, amount);

    return ();
}

@external
func executeFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256
) {
    let (caller) = get_caller_address();
    let (owner) = _owner.read();
    let (pool) = _pool.read();

    // Sender must be _owner
    assert caller = owner;

    // Execute flash loan
    IUnstoppableLender.flashLoan(pool, amount);

    return ();
}
