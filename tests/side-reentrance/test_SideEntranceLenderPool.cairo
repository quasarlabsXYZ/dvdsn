%lang starknet
from src.SideEntranceLenderPool import depositTokens, withdrawTokens, flashLoan, userBalance, damnValuableToken, _poolBalance, _userBalance, _receiverUnstoppable
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_add, assert_uint256_eq, uint256_sub,  uint256_eq
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from src.damn_valuable_token import (
    NAME,
    SYMBOL,
    DECIMALS,
    INITIAL_SUPPLY
)
@contract_interface
namespace ISELP {
func depositTokens(amount: Uint256) {
    }
func withdrawTokens() {
    }
func userBalance(account: felt) -> (amount: Uint256){
}

func pool_Balance() -> (amount: Uint256){
}
    
}
@external
func __setup__{
    syscall_ptr: felt*, range_check_ptr
}() {
    alloc_locals;

    local DVT: felt;
    local SELP: felt; 
    local admin = 'starknet-admin';

    %{
        context.DVT = deploy_contract("src/damn_valuable_token.cairo", [ids.admin]).contract_address
        context.admin = ids.admin
        ids.DVT = context.DVT
        context.SELP = deploy_contract("src/SideEntranceLenderPool.cairo", [context.DVT]).contract_address
        ids.SELP = context.SELP

    %}
    %{ stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.DVT) %}
    IERC20.approve(DVT, SELP, Uint256(INITIAL_SUPPLY, 0));
    %{ stop_prank_callable() %}
    return ();
}

@external
func test_depositTokens{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local DVT: felt;
    local SELP: felt;
    local admin: felt; 
    local deposit_amnt = 100;
    

    %{
        ids.SELP = context.SELP
        ids.admin = context.admin
        ids.DVT = context.DVT
    %}

   
    %{ stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.SELP) %}
    ISELP.depositTokens(SELP, Uint256(deposit_amnt, 0));
    // let (caller) = get_caller_address();
    let (usrBal) = ISELP.userBalance(SELP, admin);
    assert usrBal = Uint256(deposit_amnt,0);
    let (pool_bal) = ISELP.pool_Balance(SELP);
    assert pool_bal = Uint256(deposit_amnt,0);

    %{ stop_prank_callable() %}

    return ();
}

@external
func test_withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    alloc_locals;

    local DVT: felt;
    local SELP: felt;
    local admin: felt; 
    local deposit_amnt = 100;
    

    %{
        ids.SELP = context.SELP
        ids.admin = context.admin
        ids.DVT = context.DVT
    %}
    %{ stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.SELP) %}
    ISELP.depositTokens(SELP, Uint256(deposit_amnt, 0));
    ISELP.withdrawTokens(SELP);
    // let (caller) = get_caller_address();
    let (usrBal) = ISELP.userBalance(SELP, admin);
    assert usrBal = Uint256(0,0);
    let (pool_bal) = ISELP.pool_Balance(SELP);
    assert pool_bal = Uint256(0,0);

    %{ stop_prank_callable() %}

    return ();

    
}