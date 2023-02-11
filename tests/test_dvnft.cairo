%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.IERC721Metadata import IERC721Metadata

from openzeppelin.account.presets.Account import Account

from src.IDamnValuableNFT import IDamnValuableNFT

from src.DamnValuableNFT import NAME, SYMBOL

const MAX_SUPPLY = 5;

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local adminAccount: felt;
    local DVNFT: felt;

    %{
        context.adminAccount = deploy_contract("lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", [69420]).contract_address
        context.DVNFT = deploy_contract("src/DamnValuableNFT.cairo", [context.adminAccount, ids.MAX_SUPPLY]).contract_address
    %}

    return ();
}

@external
func test_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local DVNFT: felt;

    %{ ids.DVNFT = context.DVNFT %}

    let (name) = IERC721Metadata.name(DVNFT);
    assert name = NAME;

    return ();
}

@external
func test_symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local DVNFT: felt;

    %{ ids.DVNFT = context.DVNFT %}

    let (symbol) = IERC721Metadata.symbol(DVNFT);
    assert symbol = SYMBOL;

    return ();
}

@external
func test_maxSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local DVNFT: felt;

    %{ ids.DVNFT = context.DVNFT %}

    let (maxSupply) = IDamnValuableNFT.maxSupply(DVNFT);
    assert maxSupply = MAX_SUPPLY;

    return ();
}

@external
func test_holdings{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVNFT: felt;
    local adminAccount: felt;

    %{
        ids.DVNFT = context.DVNFT
        ids.adminAccount = context.adminAccount
    %}

    let (admin_holding) = IERC721.balanceOf(DVNFT, adminAccount);
    let (res) = uint256_eq(admin_holding, Uint256(0, 0));
    with_attr error_message("Admin should own 0 DVNFT") {
        assert res = 1;
    }

    return ();
}

@external
func test_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVNFT: felt;
    local adminAccount: felt;

    %{
        ids.DVNFT = context.DVNFT
        ids.adminAccount = context.adminAccount
    %}

    %{ stop_prank_callable = start_prank(ids.adminAccount, target_contract_address=ids.DVNFT) %}
    IDamnValuableNFT.mint(DVNFT, adminAccount);
    IDamnValuableNFT.mint(DVNFT, adminAccount);
    %{ stop_prank_callable() %}

    let (admin_holding) = IERC721.balanceOf(DVNFT, adminAccount);
    let (res) = uint256_eq(admin_holding, Uint256(2, 0));
    with_attr error_message("Admin should own 2 DVNFT") {
        assert res = 1;
    }

    let (totalSupply) = IDamnValuableNFT.totalSupply(DVNFT);
    with_attr error_message("totalSupply is 2") {
        assert totalSupply = 2;
    }

    return ();
}

@external
func test_mint_exceed_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local DVNFT: felt;
    local adminAccount: felt;

    %{
        ids.DVNFT = context.DVNFT
        ids.adminAccount = context.adminAccount
    %}

    %{ stop_prank_callable = start_prank(ids.adminAccount, target_contract_address=ids.DVNFT) %}
    IDamnValuableNFT.mint(DVNFT, adminAccount);
    IDamnValuableNFT.mint(DVNFT, adminAccount);
    IDamnValuableNFT.mint(DVNFT, adminAccount);
    IDamnValuableNFT.mint(DVNFT, adminAccount);
    IDamnValuableNFT.mint(DVNFT, adminAccount);

    let (totalSupply) = IDamnValuableNFT.totalSupply(DVNFT);
    with_attr error_message("totalSupply is 5") {
        assert totalSupply = 5;
    }

    %{ expect_revert(error_message="mint: exceed maxSupply") %}
    IDamnValuableNFT.mint(DVNFT, adminAccount);

    %{ stop_prank_callable() %}

    return ();
}
