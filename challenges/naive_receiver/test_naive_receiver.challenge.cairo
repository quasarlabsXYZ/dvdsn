%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import (Uint256, assert_uint256_eq)
from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.syscalls import (get_caller_address)

from openzeppelin.token.erc20.IERC20 import IERC20

from ERC3156_starknet.contracts.interfaces.IERC3156FlashLender import IERC3156FlashLender

const ONE = 10**18;

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@view
func __setup__{
    syscall_ptr: felt*, range_check_ptr
}() {
    alloc_locals;

    local DVT: felt;
    local NAIVE_RECEIVER_LENDER_POOL: felt;
    local FLASH_LOAN_RECEIVER: felt;
    local admin = 'starknet-admin';

    %{
        context.admin = ids.admin
        context.DVT = deploy_contract("src/DamnValuableToken.cairo", [ids.admin]).contract_address
        context.NAIVE_RECEIVER_LENDER_POOL = deploy_contract("src/naive_receiver/NaiveReceiverLenderPool.cairo", [context.DVT]).contract_address
        context.FLASH_LOAN_RECEIVER = deploy_contract("src/naive_receiver/FlashLoanReceiver.cairo", [context.NAIVE_RECEIVER_LENDER_POOL,context.DVT]).contract_address
    %}

    %{ 
        ids.DVT = context.DVT
        ids.NAIVE_RECEIVER_LENDER_POOL = context.NAIVE_RECEIVER_LENDER_POOL
        ids.FLASH_LOAN_RECEIVER = context.FLASH_LOAN_RECEIVER
    %}

    %{ stop_prank_callable = start_prank(ids.admin, target_contract_address=ids.DVT) %}

    //send 5 DVT to FLASH_LOAN_RECEIVER
    IERC20.transfer(DVT, FLASH_LOAN_RECEIVER, Uint256(5 * ONE,0) );
  
    //send 1000 DVT to NAIVE_RECEIVER_LENDER_POOL
    IERC20.transfer(DVT,NAIVE_RECEIVER_LENDER_POOL,Uint256(1000 * ONE,0));
   
    %{ stop_prank_callable() %}

    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                   Hacking                                  * //
// * -------------------------------------------------------------------------- * //

@external
func test_hack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(){
    check_initialization();
    attack();
    check_result();

    return ();
}

@external
func check_initialization{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local DVT: felt;
    local NAIVE_RECEIVER_LENDER_POOL: felt;
    local FLASH_LOAN_RECEIVER: felt;

    %{ 
        ids.DVT = context.DVT
        ids.NAIVE_RECEIVER_LENDER_POOL = context.NAIVE_RECEIVER_LENDER_POOL
        ids.FLASH_LOAN_RECEIVER = context.FLASH_LOAN_RECEIVER
    %}
 
    let (balance_receiver: Uint256) = IERC20.balanceOf(DVT,FLASH_LOAN_RECEIVER);
    assert_uint256_eq(balance_receiver,Uint256(5 * ONE,0));

    let (balance_pool: Uint256) = IERC20.balanceOf(DVT,NAIVE_RECEIVER_LENDER_POOL);
    assert_uint256_eq(balance_pool,Uint256(1000 * ONE,0));
   
    return ();
}


@external
func attack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {  
    alloc_locals;

    local DVT: felt;
    local NAIVE_RECEIVER_LENDER_POOL: felt;
    local FLASH_LOAN_RECEIVER: felt;

    local attacker = 'starknet-attacker';
 
    %{ 
        ids.DVT = context.DVT 
        ids.NAIVE_RECEIVER_LENDER_POOL = context.NAIVE_RECEIVER_LENDER_POOL 
        ids.FLASH_LOAN_RECEIVER = context.FLASH_LOAN_RECEIVER 
    %}

    // * ---------------------------- Your code here... --------------------------- * //



    // * -------------------------------- Checking -------------------------------- * //
  
    check_result();

    %{ print("Naive Receiver: Challenge Completed! ✨") %}

    return();
}


@external
func check_result{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
  
    alloc_locals;

    local DVT: felt;
    local NAIVE_RECEIVER_LENDER_POOL: felt;
    local FLASH_LOAN_RECEIVER: felt;
 
    %{ 
    ids.DVT = context.DVT 
    ids.NAIVE_RECEIVER_LENDER_POOL = context.NAIVE_RECEIVER_LENDER_POOL 
    ids.FLASH_LOAN_RECEIVER = context.FLASH_LOAN_RECEIVER 
    %}

    // FLASH_LOAN_RECEIVER balance is 0
    let (balance_receiver: Uint256) = IERC20.balanceOf(DVT,FLASH_LOAN_RECEIVER);
    assert_uint256_eq(balance_receiver,Uint256(0,0));
    
    // NAIVE_RECEIVER_LENDER_POOL balance is 1000 + 5
    let (balance_pool: Uint256) = IERC20.balanceOf(DVT,NAIVE_RECEIVER_LENDER_POOL);
    assert_uint256_eq(balance_pool,Uint256(1005 * ONE,0));

    return();
}



