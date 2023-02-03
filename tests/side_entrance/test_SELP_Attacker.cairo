%lang starknet
// from src.SideEntranceLenderPool import depositTokens, withdrawTokens, flashLoan, userBalance, damnValuableToken, _poolBalance, _userBalance, _receiverUnstoppable
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_add,
    assert_uint256_eq,
    uint256_sub,
    uint256_eq,
)
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from src.DamnValuableToken import NAME, SYMBOL, DECIMALS, INITIAL_SUPPLY

@contract_interface
namespace ISELP {
    func depositTokens(amount: Uint256) {
    }
    func withdrawTokens() {
    }
    func userBalance(account: felt) -> (amount: Uint256) {
    }

    func flashloan(amount: Uint256) {
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

@contract_interface
namespace IATTACK {
    func _pool() -> (res: felt) {
    }
    func _owner() -> (res: felt) {
    }
    func execute() {
    }
    func borrow() {
    }
}

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local SELP: felt;
    local ATTACKER: felt;
    local admin = 'starknet-admin';
    local deposit_amnt = 100;

    %{
        context.DVT = deploy_contract("src/DamnValuableToken.cairo", [ids.admin]).contract_address
        context.admin = ids.admin
        ids.DVT = context.DVT
        context.SELP = deploy_contract("src/side_entrance/SideEntranceLenderPool.cairo", [context.DVT]).contract_address
        ids.SELP = context.SELP
        context.ATTACKER = deploy_contract("src/side_entrance/SideEntranceLenderPool.attacker.cairo", [context.SELP, context.DVT]).contract_address
        ids.ATTACKER = context.ATTACKER
    %}

    %{ stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.DVT) %}
    IERC20.approve(DVT, SELP, Uint256(INITIAL_SUPPLY, 0));

    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.SELP) %}
    ISELP.depositTokens(SELP, Uint256(deposit_amnt, 0));

    %{ stop_prank_callable() %}

    return ();
}

@external
func test_attack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local SELP: felt;
    local admin: felt;
    local deposit_amnt = 100;
    local ATTACKER: felt;

    %{
        ids.SELP = context.SELP
        ids.admin = context.admin
        ids.DVT = context.DVT
        ids.ATTACKER = context.ATTACKER
        print("attacker" + str(context.ATTACKER))
    %}

    IATTACK.borrow(ATTACKER);
    let (benefits) = IERC20.balanceOf(DVT, ATTACKER);
    assert benefits = Uint256(deposit_amnt, 0);

    return ();
}
