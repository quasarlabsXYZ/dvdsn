%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_block_number,
)
from starkware.cairo.common.uint256 import (
    Uint256,
    assert_uint256_eq,
    assert_uint256_lt,
    assert_uint256_le,
)
from starkware.cairo.common.math import assert_not_zero
from openzeppelin.token.erc20.IERC20 import IERC20

from src.the_rewarder.interfaces.IAccountingToken import IAccountingToken
from src.the_rewarder.interfaces.IFlashLoanerPool import IFlashLoanerPool
from src.the_rewarder.interfaces.ITheRewarderPool import ITheRewarderPool
from src.the_rewarder.interfaces.IRewardToken import IRewardToken

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

const MINTER_ROLE = 1;
const SNAPSHOT_ROLE = 2;
const BURNER_ROLE = 3;
const ADMIN_ROLE = 0;

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address: felt;
    local tokens_in_pool: Uint256 = Uint256(1000000, 0);
    local initial_attacker_token_balance: Uint256 = Uint256(100, 0);

    local DVT: felt;
    local THE_REWARDER_POOL: felt;
    local FLASHLOANER_POOL: felt;

    local REWARD_TOKEN: felt;
    local ACCOUNTING_TOKEN: felt;

    local deployer = 'starknet-deployer';
    local attacker = 'starknet-attacker';
    local random_user = 'bob';
    %{
        context.accounting_class_hash = declare("./src/the_rewarder/AccountingToken.cairo").class_hash
        context.reward_class_hash = declare("./src/the_rewarder/RewardToken.cairo").class_hash

        context.DVT = deploy_contract("src/damn_valuable_token.cairo", [ids.deployer]).contract_address
        context.THE_REWARDER_POOL = deploy_contract("./src/the_rewarder/TheRewarderPool.cairo", [context.DVT, context.accounting_class_hash, context.reward_class_hash]).contract_address
        context.FLASHLOANER_POOL = deploy_contract("./src/the_rewarder/FlashLoanerPool.cairo", [context.DVT]).contract_address

        ids.DVT = context.DVT
        ids.THE_REWARDER_POOL = context.THE_REWARDER_POOL
        ids.FLASHLOANER_POOL = context.FLASHLOANER_POOL

        context.deployer = ids.deployer
        context.attacker = ids.attacker
        context.bob = ids.random_user
        context.accouting_address = load(ids.THE_REWARDER_POOL, "accounting_token", "felt")[0]
        context.rewards_address = load(ids.THE_REWARDER_POOL, "reward_token", "felt")[0]

        ids.REWARD_TOKEN = context.rewards_address
        ids.ACCOUNTING_TOKEN = context.accouting_address
    %}

    // Set initial token balance of the pool offering flash loans
    %{ stop_roll = roll(0) %}

    %{ stop_prank_callable = start_prank(ids.deployer, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, FLASHLOANER_POOL, tokens_in_pool);
    %{ stop_prank_callable() %}
    let (FLASHLOANER_POOL_balance) = IERC20.balanceOf(DVT, FLASHLOANER_POOL);
    with_attr error_message("Pool should have initial token amount") {
        assert_uint256_eq(FLASHLOANER_POOL_balance, tokens_in_pool);
    }
    let (bool) = IAccountingToken.has_role(ACCOUNTING_TOKEN, MINTER_ROLE, THE_REWARDER_POOL);
    with_attr error_message("THE_REWARDER_POOL should have MINTER_ROLE") {
        assert bool = 1;
    }
    let (bool2) = IAccountingToken.has_role(ACCOUNTING_TOKEN, SNAPSHOT_ROLE, THE_REWARDER_POOL);
    with_attr error_message("THE_REWARDER_POOL should have SNAPSHOT_ROLE") {
        assert bool2 = 1;
    }
    let (bool3) = IAccountingToken.has_role(ACCOUNTING_TOKEN, BURNER_ROLE, THE_REWARDER_POOL);
    with_attr error_message("THE_REWARDER_POOL should have BURNER_ROLE") {
        assert bool3 = 1;
    }
    %{ stop_prank_callable = start_prank(ids.deployer, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, random_user, Uint256(100, 0));
    %{ stop_prank_callable() %}
    %{ stop_prank_callable = start_prank(ids.random_user, target_contract_address=ids.DVT) %}
    IERC20.approve(DVT, THE_REWARDER_POOL, Uint256(100, 0));
    %{ stop_prank_callable() %}
    %{ stop_prank_callable = start_prank(ids.random_user, target_contract_address=ids.THE_REWARDER_POOL) %}
    ITheRewarderPool.deposit(THE_REWARDER_POOL, Uint256(100, 0));
    %{ stop_prank_callable() %}
    let (rewarder_bal) = IERC20.balanceOf(DVT, THE_REWARDER_POOL);
    with_attr error_message("THE_REWARDER_POOL should have recived bob deposit") {
        assert rewarder_bal.low = 100;
    }
    let (bob_accounting_bal) = IAccountingToken.balance_of(ACCOUNTING_TOKEN, random_user);
    with_attr error_message("Bob should have accounting tokens") {
        assert bob_accounting_bal.low = 100;
    }
    let (total_rewards) = IRewardToken.totalSupply(REWARD_TOKEN);
    with_attr error_message("REWARD_TOKEN should have 0 supply") {
        assert total_rewards.low = 0;
    }
    let (attacker_bal) = IERC20.balanceOf(DVT, attacker);
    with_attr error_message("attacker should have 0 tokens") {
        assert attacker_bal.low = 0;
    }
    %{ stop_roll() %}
    %{ stop_roll = roll(101) %}
    let rewards = 100;
    %{ stop_prank_callable = start_prank(ids.random_user, target_contract_address=ids.THE_REWARDER_POOL) %}
    let (value: Uint256) = ITheRewarderPool.distributeRewards(THE_REWARDER_POOL);

    let (bob_balance) = IRewardToken.balanceOf(REWARD_TOKEN, random_user);
    with_attr error_message("bob should have rewards tokens") {
        assert bob_balance.low = 100;
    }
    %{ stop_prank_callable() %}

    %{ stop_roll() %}

    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                   Hacking                                  * //
// * -------------------------------------------------------------------------- * //

@external
func test_hack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local THE_REWARDER_POOL: felt;
    local FLASHLOANER_POOL: felt;

    local REWARD_TOKEN: felt;
    local ACCOUNTING_TOKEN: felt;

    local attacker: felt;

    local initial_attacker_token_balance: Uint256 = Uint256(100, 0);
    local tokens_in_pool: Uint256 = Uint256(1000000, 0);

    local round_number: felt;

    local random_user: felt;
    %{
        ids.DVT = context.DVT
        ids.THE_REWARDER_POOL = context.THE_REWARDER_POOL
        ids.FLASHLOANER_POOL = context.FLASHLOANER_POOL
        ids.REWARD_TOKEN = context.rewards_address
        ids.ACCOUNTING_TOKEN = context.accouting_address

        ids.attacker = context.attacker
        ids.random_user = context.bob
    %}

    // * ---------------------------- Your code here... --------------------------- * //

    // * -------------------------------- Checking -------------------------------- * //

    %{
        context.round_number = load(ids.THE_REWARDER_POOL, "round_number", "felt")[0]
        ids.round_number = context.round_number;
    %}
    // Only one round must have taken place
    with_attr error_message("Round number should be 3") {
        assert round_number = 3;
    }

    // Users should get neglegible rewards this round
    ITheRewarderPool.distributeRewards(THE_REWARDER_POOL);
    let (bob_rewards: Uint256) = IRewardToken.balanceOf(REWARD_TOKEN, random_user);

    with_attr error_message("bob rewards should be low") {
        assert_uint256_lt(bob_rewards.low, Uint256(100, 0));
    }

    // Rewards must have been issued to the player account
    let (reward_supply) = IRewardToken.totalSupply(REWARD_TOKEN);
    with_attr error_message("Rewards should have be minted") {
        assert_uint256_lt(Uint256(100, 0), reward_supply);
    }
    let (attacker_rewards) = IRewardToken.balanceOf(REWARD_TOKEN, attacker);
    with_attr error_message("attacker should have rewards") {
        assert_not_zero(attacker_rewards.low);
    }
    // Balance of DVT tokens in player and lending pool hasn't changed
    let (attacker_bal) = IERC20.balanceOf(DVT, attacker);
    with_attr error_message("attacker should have 0 DVT") {
        assert attacker_bal.low = 0;
    }
    let (flashloanpool_bal) = IERC20.balanceOf(DVT, FLASHLOANER_POOL);
    with_attr error_message("FlashloanerPool should have tokens_in_pool DVT") {
        assert flashloanpool_bal.low = tokens_in_pool.low;
    }

    %{ print("The Rewarder: Challenge Completed! ✨") %}

    return ();
}
