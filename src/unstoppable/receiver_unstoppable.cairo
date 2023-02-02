%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from lib.cairo_contracts.src.openzeppelin.token.erc20.IERC20 import IERC20
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

@contract_interface
namespace IUnstoppableLender {
    func deposit_tokens(amount: Uint256) {
    }

    func flash_loan(borrow_amount: Uint256) {
    }
}

@storage_var
func owner() -> (res: felt) {
}

@storage_var
func pool() -> (res: felt) {
}


@constructor
func constructor{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
    }(pool_address: felt) {
    pool.write(pool_address);
    let (caller) = get_caller_address();
    owner.write(caller);
    return ();
}

@external
func receive_tokens{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
    }(token_address: felt, amount: Uint256) {
    let (caller) = get_caller_address();
    let (pool_address) = pool.read();

    assert caller = pool_address; // sender must be pool
    //Return all tokens to the pool

    IERC20.transfer(token_address, caller, amount);
    return ();
}

@external
func execute_flash_loan{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
    }(amount: Uint256) {
    let (caller) = get_caller_address();
    let (own) = owner.read();
    let (pool_address) = pool.read();
    assert caller = own;
    IUnstoppableLender.flash_loan(pool_address, amount);
    return ();
}

