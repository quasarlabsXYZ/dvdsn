%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, assert_uint256_lt, uint256_add, assert_uint256_le, assert_uint256_eq
from lib.cairo_contracts.src.openzeppelin.token.erc20.IERC20 import IERC20
from lib.cairo_contracts.src.openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.math import assert_le_felt, assert_lt_felt


@contract_interface
namespace IReceiverUnstoppable {
    func receive_tokens(token_address: felt, amount: Uint256) {
    }
}

@storage_var
func damn_valuable_token() -> (res: felt) {
}

@storage_var
func pool_balance() -> (res: Uint256) {
}

@storage_var
func receiver_unstoppable_address() -> (res: felt) {
}

@constructor
func constructor{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
    }(token_address: felt) {
    assert_lt_felt(0, token_address);
    damn_valuable_token.write(token_address);
    return ();
}

@external
func deposit_tokens{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
    }(amount: Uint256) {
    ReentrancyGuard.start();
    assert_uint256_lt(Uint256(0,0), amount);
    let (dvt) = damn_valuable_token.read();
    let (caller) = get_caller_address();
    let (contract) = get_contract_address();

    IERC20.transferFrom(dvt, caller, contract, amount);

    let (original_balance) = pool_balance.read();
    let (new_balance, _) = uint256_add(original_balance, amount);
    pool_balance.write(new_balance);
    ReentrancyGuard.end();
    return ();
}

@external
func flash_loan{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
    }(borrow_amount: Uint256) {
    alloc_locals;
    ReentrancyGuard.start();
    assert_uint256_lt(Uint256(0, 0), borrow_amount);
    let (local dvt) = damn_valuable_token.read();
    let (local caller) = get_caller_address();
    let (local contract) = get_contract_address();
    let (balance_before) = IERC20.balanceOf(dvt, contract);
    let (pool_bal) = pool_balance.read();
    assert_uint256_le(borrow_amount, balance_before);
    assert_uint256_eq(pool_bal, balance_before);

    let (receiver_address) = receiver_unstoppable_address.read();

    IERC20.transfer(dvt, receiver_address, borrow_amount);

    let (lender_balance) = IERC20.balanceOf(dvt, contract);
    let (receiver_balance) = IERC20.balanceOf(dvt, receiver_address);
    let (caller_balance) = IERC20.balanceOf(dvt, caller);
    
    %{
        print("caller_address", ids.caller)
        print("caller_balance", ids.caller_balance.low)
        print("receiver_address", ids.receiver_address)
        print("lender balance", ids.lender_balance.low)
        print("borrow_amount", ids.borrow_amount.low)
        print("receiver balance", ids.receiver_balance.low)
    %}
    IReceiverUnstoppable.receive_tokens(receiver_address, dvt, borrow_amount);

    let balance_after: Uint256 = IERC20.balanceOf(dvt, contract);
    assert_uint256_le(balance_before, balance_after);
    ReentrancyGuard.end();
    return ();
}

@external
func set_receiver_unstoppable_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    receiver_unstoppable: felt
) {
    receiver_unstoppable_address.write(receiver_unstoppable);
    return ();
}




