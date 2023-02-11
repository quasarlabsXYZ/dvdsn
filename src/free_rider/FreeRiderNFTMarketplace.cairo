// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le
from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721
from src.IDamnValuableNFT import IDamnValuableNFT

from openzeppelin.utils.constants.library import IERC721_RECEIVER_ID
from openzeppelin.introspection.erc165.library import ERC165

from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.syscalls import deploy, get_contract_address, get_caller_address

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero

const MAX_SUPPLY = 5;

//
//   EVENTS
//

@event
func nft_offered(offerer: felt, token_id: Uint256, price: Uint256) {
}

@event
func nft_bought(buyer: felt, token_id: Uint256, price: Uint256) {
}

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
func Offers(token_id: Uint256) -> (res: Uint256) {
}

@storage_var
func Offers_count() -> (res: felt) {
}

//
//  VIEWS
//

@view
func get_NFT_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    nft_address: felt
) {
    let (nft_address) = NFT_address.read();
    return (nft_address=nft_address);
}

@view
func get_Offers_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    offers_count: felt
) {
    let (offers_count) = Offers_count.read();
    return (offers_count=offers_count);
}

//
//  LOGIC
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt, DVNFT_class_hash: felt
) {
    alloc_locals;

    Token_address.write(token);

    let (this) = get_contract_address();
    let (caller) = get_caller_address();

    // deploy DVNFT
    let (local nft_address: felt) = deploy(
        class_hash=DVNFT_class_hash,
        contract_address_salt=0,
        constructor_calldata_size=2,
        constructor_calldata=cast(new (this, MAX_SUPPLY), felt*),
        deploy_from_zero=FALSE,
    );

    NFT_address.write(nft_address);

    _mintDVNFT(nft_address, caller, 5);

    IDamnValuableNFT.renounceOwnership(nft_address);

    return ();
}

@external
func offerMany{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_ids_len: felt, token_ids: Uint256*, price: Uint256
) {
    if (token_ids_len == 0) {
        return ();
    }

    let token_id = token_ids[token_ids_len - 1];
    _offer(token_id, price);
    return offerMany(token_ids_len - 1, token_ids, price);
}

@external
func buyMany{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_ids_len: felt, token_ids: Uint256*
) {
    if (token_ids_len == 0) {
        return ();
    }

    let token_id = token_ids[token_ids_len - 1];
    _buy(token_id);
    return buyMany(token_ids_len - 1, token_ids);
}

//
//  HELPERS
//

func _mintDVNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nft_address: felt, to: felt, count: felt
) {
    if (count == 0) {
        return ();
    }

    IDamnValuableNFT.mint(nft_address, to);
    return _mintDVNFT(nft_address, to, count - 1);
}

func _offer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, price: Uint256
) {
    let (this) = get_contract_address();
    let (caller) = get_caller_address();
    let (nft_address) = NFT_address.read();

    // price > 0
    let (res) = uint256_le(price, Uint256(0, 0));
    with_attr error_message("Price must be > 0") {
        assert res = 0;
    }

    // check if caller is NFT owner
    let (token_owner) = IERC721.ownerOf(nft_address, token_id);
    with_attr error_message("Caller is not DVNFT Owner") {
        assert caller = token_owner;
    }

    // check approval
    let (is_approved) = IERC721.getApproved(nft_address, token_id);
    let (is_approved_for_all) = IERC721.isApprovedForAll(nft_address, caller, this);
    let approved = is_approved + is_approved_for_all;

    with_attr error_message("Invalid Approval") {
        assert_not_zero(approved);
    }

    // save offer
    Offers.write(token_id, price);

    // update Offers_count
    let (current_offers_count) = Offers_count.read();
    Offers_count.write(current_offers_count + 1);

    // emit nft_offered Event
    nft_offered.emit(offerer=caller, token_id=token_id, price=price);

    return ();
}

func _buy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: Uint256) {
    alloc_locals;
    local pedersen_ptr: HashBuiltin* = pedersen_ptr;

    let price: Uint256 = Offers.read(token_id);
    let (is_zero) = uint256_le(price, Uint256(0, 0));
    with_attr error_message("Token not offered!") {
        assert is_zero = 0;
    }

    let (this) = get_contract_address();
    let (caller) = get_caller_address();
    let (nft_address) = NFT_address.read();
    let (token_address) = Token_address.read();
    let (owner) = IERC721.ownerOf(nft_address, token_id);

    let (data: felt*) = alloc();

    // transfer from seller to buyer
    IERC721.safeTransferFrom(nft_address, owner, caller, token_id, 0, data);

    // update Offers_count
    let (offers_count) = Offers_count.read();
    Offers_count.write(offers_count - 1);

    // pay seller
    let (owner) = IERC721.ownerOf(nft_address, token_id);
    IERC20.transfer(token_address, owner, price);

    // emit nft_bought Event
    nft_bought.emit(buyer=caller, token_id=token_id, price=price);

    return ();
}
