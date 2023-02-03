%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, assert_uint256_eq

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

        context.accouting_address = load(ids.THE_REWARDER_POOL, "accounting_token", "felt")[0]
        context.rewards_address = load(ids.THE_REWARDER_POOL, "reward_token", "felt")[0]

        ids.REWARD_TOKEN = context.rewards_address
        ids.ACCOUNTING_TOKEN = context.accouting_address
    %}

    // Set initial token balance of the pool offering flash loans
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

    %{
        print("DVT" + str(context.DVT))
        print("THE_REWARDER_POOL" + str(context.THE_REWARDER_POOL))
        print("FLASHLOANER_POOL" + str(context.FLASHLOANER_POOL))
        print("accouting_address" + str(context.accouting_address))
        print("rewards_address" + str(context.rewards_address))
        ids.DVT = context.DVT
        ids.THE_REWARDER_POOL = context.THE_REWARDER_POOL
        ids.FLASHLOANER_POOL = context.FLASHLOANER_POOL
        ids.REWARD_TOKEN = context.rewards_address
        ids.ACCOUNTING_TOKEN = context.accouting_address

        ids.attacker = context.attacker
    %}

    // * ---------------------------- Your code here... --------------------------- * //

    // * -------------------------------- Checking -------------------------------- * //

    %{ print("The Rewarder: Challenge Completed! ✨") %}

    return ();
}
