%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from openzeppelin.token.erc20.IERC20 import IERC20

from src.DamnValuableToken import NAME, SYMBOL, DECIMALS, INITIAL_SUPPLY

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local deployer = 'starknet-deployer';

    %{
        context.DVT = deploy_contract("src/DamnValuableToken.cairo", [ids.deployer]).contract_address
        context.deployer = ids.deployer
    %}

    return ();
}

@external
func test_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local DVT: felt;

    %{ ids.DVT = context.DVT %}

    let (name) = IERC20.name(DVT);
    assert name = NAME;

    return ();
}

@external
func test_symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local DVT: felt;

    %{ ids.DVT = context.DVT %}

    let (symbol) = IERC20.symbol(DVT);
    assert symbol = SYMBOL;

    return ();
}

@external
func test_decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local DVT: felt;

    %{ ids.DVT = context.DVT %}

    let (decimals) = IERC20.decimals(DVT);
    assert decimals = DECIMALS;

    return ();
}

@external
func test_token_holdings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local deployer: felt;

    %{
        ids.DVT = context.DVT
        ids.deployer = context.deployer
    %}

    let (deployer_holding) = IERC20.balanceOf(DVT, deployer);
    let (res) = uint256_eq(deployer_holding, Uint256(INITIAL_SUPPLY, 0));

    assert res = 1;

    return ();
}

@external
func test_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVT: felt;
    local deployer: felt;
    local alice = 'alice';
    local transfer_amt = 100;

    %{
        ids.DVT = context.DVT
        ids.deployer = context.deployer
    %}

    %{ stop_prank_callable = start_prank(ids.deployer, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, alice, Uint256(transfer_amt, 0));
    %{ stop_prank_callable() %}

    let (deployer_holding) = IERC20.balanceOf(DVT, deployer);
    let (res) = uint256_eq(deployer_holding, Uint256(INITIAL_SUPPLY - transfer_amt, 0));
    assert res = 1;

    let (alice_holding) = IERC20.balanceOf(DVT, alice);
    let (res) = uint256_eq(alice_holding, Uint256(transfer_amt, 0));
    assert res = 1;

    return ();
}
