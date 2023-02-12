%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.alloc import alloc

from openzeppelin.token.erc20.IERC20 import IERC20

from src.truster.interfaces.ITrusterLenderPool import ITrusterLenderPool
from src.DamnValuableToken import INITIAL_SUPPLY

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local TRUSTER_POOL: felt;

    local deployer = 'starknet-deployer';

    %{
        context.DVT = deploy_contract("src/DamnValuableToken.cairo", [ids.deployer]).contract_address
        context.TRUSTER_POOL = deploy_contract("src/truster/TrusterLenderPool.cairo", [context.DVT]).contract_address
        context.deployer = ids.deployer

        ids.DVT = context.DVT
        ids.TRUSTER_POOL = context.TRUSTER_POOL
    %}

    %{ stop_prank_callable = start_prank(ids.deployer, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, TRUSTER_POOL, Uint256(INITIAL_SUPPLY, 0));
    %{ stop_prank_callable() %}

    let (pool_balance) = IERC20.balanceOf(DVT, TRUSTER_POOL);

    let (res) = uint256_eq(pool_balance, Uint256(INITIAL_SUPPLY, 0));
    assert res = 1;

    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                   Hacking                                  * //
// * -------------------------------------------------------------------------- * //

@external
func test_hack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local TRUSTER_POOL: felt;
    local attacker = 'starknet-attacker';

    %{
        ids.DVT = context.DVT
        ids.TRUSTER_POOL = context.TRUSTER_POOL
    %}

    // * ---------------------------- Your code here... --------------------------- * //



    // * -------------------------------- Checking -------------------------------- * //

    let (pool_balance: Uint256) = IERC20.balanceOf(DVT, TRUSTER_POOL);
    let (attacker_balance: Uint256) = IERC20.balanceOf(DVT, attacker);

    let (pool_res) = uint256_eq(pool_balance, Uint256(0, 0));
    assert pool_res = 1;

    let (attacker_res) = uint256_eq(attacker_balance, Uint256(INITIAL_SUPPLY, 0));
    assert attacker_res = 1;

    %{ print("Truster: Challenge Completed! ✨") %}

    return ();
}
