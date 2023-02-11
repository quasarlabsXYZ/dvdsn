%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, assert_uint256_eq, uint256_le
from starkware.cairo.common.alloc import alloc

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721

from src.utils.simple_flash_lender.interfaces.ISimpleFlashLender import ISimpleFlashLender
from src.free_rider.interfaces.IFreeRiderNFTMarketplace import IFreeRiderNFTMarketplace
from src.free_rider.interfaces.IFreeRiderAttacker import IFreeRiderAttacker

const ONE = 10 ** 18;

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    %{ print("__setup__") %}

    local player = 'the-player';
    local adminAccount: felt;
    local DVNFT_class_hash: felt;

    local DVT: felt;
    local DVNFT: felt;
    local SimpleFlashLender: felt;
    local FreeRiderNFTMarketplace: felt;
    local FreeRiderRecovery: felt;

    %{
        context.player = ids.player
        context.adminAccount = deploy_contract("lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", [69420]).contract_address
        context.DVNFT_class_hash = declare("./src/DamnValuableNFT.cairo").class_hash
        context.DVT = deploy_contract("src/DamnValuableToken.cairo", [context.adminAccount]).contract_address
        context.SimpleFlashLender = deploy_contract("src/utils/simple_flash_lender/SimpleFlashLender.cairo", [context.adminAccount]).contract_address
                    
        ids.adminAccount = context.adminAccount
        ids.DVT = context.DVT
        ids.SimpleFlashLender = context.SimpleFlashLender

        declared_FreeRiderNFTMarketplace = declare("src/free_rider/FreeRiderNFTMarketplace.cairo")
        prepared_FreeRiderNFTMarketplace = prepare(declared_FreeRiderNFTMarketplace, [context.DVT, context.DVNFT_class_hash])
            
        stop_prank = start_prank(context.adminAccount, target_contract_address=prepared_FreeRiderNFTMarketplace.contract_address)
        context.FreeRiderNFTMarketplace = deploy(prepared_FreeRiderNFTMarketplace).contract_address
        stop_prank()
                
        ids.FreeRiderNFTMarketplace = context.FreeRiderNFTMarketplace
    %}

    let (DVNFT) = IFreeRiderNFTMarketplace.get_NFT_address(FreeRiderNFTMarketplace);

    %{
        context.FreeRiderRecovery = deploy_contract("src/free_rider/FreeRiderRecovery.cairo", [ids.DVT, ids.DVNFT, ids.player]).contract_address
        ids.FreeRiderRecovery = context.FreeRiderRecovery
    %}

    %{ print("> initialize SimpleFlashLender to support DVT") %}
    %{ stop_prank = start_prank(ids.adminAccount, target_contract_address=ids.SimpleFlashLender) %}
    ISimpleFlashLender.addSupportedToken(SimpleFlashLender, DVT);
    %{ stop_prank() %}

    %{ print("> send 1000 DVT in SimpleFlashLender") %}
    %{ stop_prank = start_prank(ids.adminAccount, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, SimpleFlashLender, Uint256(1000 * ONE, 0));
    %{ stop_prank() %}

    %{ print("> approve FreeRiderNFTMarketplace to spend DVNFT") %}
    %{ stop_prank = start_prank(ids.adminAccount, target_contract_address=ids.DVNFT) %}
    IERC721.setApprovalForAll(DVNFT, FreeRiderNFTMarketplace, 1);
    %{ stop_prank() %}

    %{ print("> create Offers (84 DVT each)") %}
    local nftPrice: Uint256 = Uint256(84 * ONE, 0);
    let (local token_ids: Uint256*) = alloc();
    assert [token_ids + 0] = Uint256(1, 0);
    assert [token_ids + 2] = Uint256(2, 0);
    assert [token_ids + 4] = Uint256(3, 0);
    assert [token_ids + 6] = Uint256(4, 0);
    assert [token_ids + 8] = Uint256(5, 0);

    %{ stop_prank = start_prank(ids.adminAccount, target_contract_address=ids.FreeRiderNFTMarketplace) %}
    IFreeRiderNFTMarketplace.offerMany(FreeRiderNFTMarketplace, 5, token_ids, nftPrice);
    // IFreeRiderNFTMarketplace.offer(FreeRiderNFTMarketplace,Uint256(1,0), nftPrice);
    %{ stop_prank() %}

    %{ print("> send 42 DVT to player") %}
    %{ stop_prank = start_prank(ids.adminAccount, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, player, Uint256(42 * ONE, 0));
    %{ stop_prank() %}

    %{ print("> send 500 DVT to FreeRiderNFTMarketplace") %}
    %{ stop_prank = start_prank(ids.adminAccount, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, FreeRiderNFTMarketplace, Uint256(500 * ONE, 0));
    %{ stop_prank() %}

    %{ print("> send 169 DVT to FreeRiderRecovery") %}
    %{ stop_prank = start_prank(ids.adminAccount, target_contract_address=ids.DVT) %}
    IERC20.transfer(DVT, FreeRiderRecovery, Uint256(169 * ONE, 0));
    %{ stop_prank() %}

    return ();
}

@external
func test_free_rider{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    check_initialization();
    attack();
    check_result();

    return ();
}

@external
func check_initialization{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    %{ print("check_initialization") %}

    local player;
    local adminAccount;
    local DVT: felt;
    local SimpleFlashLender: felt;
    local FreeRiderNFTMarketplace: felt;

    %{
        ids.player = context.player
        ids.adminAccount = context.adminAccount
        ids.DVT = context.DVT
        ids.SimpleFlashLender = context.SimpleFlashLender
        ids.FreeRiderNFTMarketplace = context.FreeRiderNFTMarketplace
    %}

    let (local DVNFT) = IFreeRiderNFTMarketplace.get_NFT_address(FreeRiderNFTMarketplace);

    %{ print("> SimpleFlashLender balance is 1000 DVT") %}
    let (balance_flash_lender: Uint256) = IERC20.balanceOf(DVT, SimpleFlashLender);
    assert_uint256_eq(balance_flash_lender, Uint256(1000 * ONE, 0));

    %{ print("> adminAccount holds 5 DVNFT") %}
    let (balance_admin: Uint256) = IERC721.balanceOf(DVNFT, adminAccount);
    assert_uint256_eq(balance_admin, Uint256(5, 0));

    %{ print("> there is 5 Offers") %}
    let (offers_count) = IFreeRiderNFTMarketplace.get_Offers_count(FreeRiderNFTMarketplace);
    assert offers_count = 5;

    %{ print("> player owns 42 DVT") %}
    let (balance_player: Uint256) = IERC20.balanceOf(DVT, player);
    assert_uint256_eq(balance_player, Uint256(42 * ONE, 0));

    return ();
}

@external
func attack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    %{ print("attack") %}

    // TODO : code your attack here

    local player;
    local DVT: felt;
    local SimpleFlashLender: felt;
    local FreeRiderNFTMarketplace: felt;
    local FreeRiderRecovery: felt;
    local FreeRiderAttacker: felt;

    %{
        ids.player = context.player
        ids.DVT = context.DVT
        ids.FreeRiderNFTMarketplace = context.FreeRiderNFTMarketplace
        ids.FreeRiderRecovery = context.FreeRiderRecovery
        ids.SimpleFlashLender = context.SimpleFlashLender
    %}

    let (DVNFT) = IFreeRiderNFTMarketplace.get_NFT_address(FreeRiderNFTMarketplace);

    %{ ids.FreeRiderAttacker = deploy_contract("src/free_rider/FreeRiderAttacker.cairo", [ids.DVT, ids.DVNFT, ids.FreeRiderNFTMarketplace, ids.SimpleFlashLender, ids.FreeRiderRecovery]).contract_address %}

    %{ print("> approve FreeRiderAttacker to spend DVT") %}
    %{ stop_prank = start_prank(ids.player, target_contract_address=ids.DVT) %}
    IERC20.approve(DVT, FreeRiderAttacker, Uint256(42 * ONE, 0));
    %{ stop_prank() %}

    %{ print("> FreeRiderAttacker.attack()") %}
    %{ stop_prank = start_prank(ids.player, target_contract_address=ids.FreeRiderAttacker) %}
    IFreeRiderAttacker.attack(FreeRiderAttacker);
    %{ stop_prank() %}

    return ();
}

@external
func check_result{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE
    %{ print("check_result") %}

    local player;
    local DVT: felt;
    local SimpleFlashLender: felt;
    local FreeRiderNFTMarketplace: felt;
    local FreeRiderRecovery: felt;
    local FreeRiderAttacker: felt;

    %{
        ids.player = context.player
        ids.DVT = context.DVT
        ids.FreeRiderNFTMarketplace = context.FreeRiderNFTMarketplace
        ids.FreeRiderRecovery = context.FreeRiderRecovery
        ids.SimpleFlashLender = context.SimpleFlashLender
    %}

    let (DVNFT) = IFreeRiderNFTMarketplace.get_NFT_address(FreeRiderNFTMarketplace);

    %{ print("> marketplace owns 0 DVNFT") %}
    let (marketplace_dvnft_bal: Uint256) = IERC721.balanceOf(DVNFT, FreeRiderNFTMarketplace);
    assert marketplace_dvnft_bal = Uint256(0, 0);

    %{ print("> recovery owns 5 DVNFT") %}
    let (recovery_dvnft_bal: Uint256) = IERC721.balanceOf(DVNFT, FreeRiderRecovery);
    assert recovery_dvnft_bal = Uint256(5, 0);

    %{ print("> recovery owns 0 DVT") %}
    let (recovery_dvt_bal: Uint256) = IERC20.balanceOf(DVT, FreeRiderRecovery);
    assert recovery_dvt_bal = Uint256(0, 0);

    %{ print("> player earned DVT from recovery") %}
    let (player_dvt_bal: Uint256) = IERC20.balanceOf(DVT, player);
    let (res) = uint256_le(player_dvt_bal, Uint256(169 * ONE, 0));
    with_attr error_message("player DVT balance too low") {
        assert res = 0;
    }

    return ();
}
