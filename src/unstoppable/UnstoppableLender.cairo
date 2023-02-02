%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    assert_uint256_lt,
    uint256_add,
    assert_uint256_le,
    assert_uint256_eq,
)
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_lt_felt

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from src.unstoppable.interfaces.IReceiverUnstoppable import IReceiverUnstoppable

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

@storage_var
func _token() -> (res: felt) {
}

@storage_var
func _poolBalance() -> (res: Uint256) {
}

@storage_var
func _receiverAddress() -> (res: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) {
    assert_lt_felt(0, token);
    _token.write(token);

    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                  Externals                                 * //
// * -------------------------------------------------------------------------- * //

@external
func depositTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256
) {
    ReentrancyGuard.start();

    assert_uint256_lt(Uint256(0, 0), amount);
    let (token) = _token.read();
    let (caller) = get_caller_address();
    let (contract) = get_contract_address();

    IERC20.transferFrom(token, caller, contract, amount);

    let (original_balance) = _poolBalance.read();
    let (new_balance, _) = uint256_add(original_balance, amount);
    _poolBalance.write(new_balance);

    ReentrancyGuard.end();

    return ();
}

@external
func flashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    borrow_amount: Uint256
) {
    alloc_locals;

    ReentrancyGuard.start();

    assert_uint256_lt(Uint256(0, 0), borrow_amount);
    let (local token) = _token.read();
    let (local caller) = get_caller_address();
    let (local contract) = get_contract_address();
    let (balance_before) = IERC20.balanceOf(token, contract);
    let (pool_balance) = _poolBalance.read();

    assert_uint256_le(borrow_amount, balance_before);
    assert_uint256_eq(pool_balance, balance_before);

    let (receiverAddress) = _receiverAddress.read();

    IERC20.transfer(token, receiverAddress, borrow_amount);

    IReceiverUnstoppable.receiveTokens(receiverAddress, token, borrow_amount);

    let balance_after: Uint256 = IERC20.balanceOf(token, contract);
    assert_uint256_le(balance_before, balance_after);

    ReentrancyGuard.end();

    return ();
}

@external
func setReceiverAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    receiver_unstoppable: felt
) {
    _receiverAddress.write(receiver_unstoppable);

    return ();
}
