// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, assert_uint256_le
from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721
from src.IDamnValuableNFT import IDamnValuableNFT

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
func Beneficiary_address() -> (res: felt) {
}

@storage_var
func Received() -> (res: felt) {
}

//
//  CONTRACT
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt, nft_address: felt, beneficiary_address: felt
) {
    ERC165.register_interface(IERC721_RECEIVER_ID);

    Token_address.write(token_address);
    NFT_address.write(nft_address);
    Beneficiary_address.write(beneficiary_address);

    let (caller) = get_caller_address();
    IERC721.setApprovalForAll(nft_address, caller, TRUE);

    return ();
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

@view
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, from_: felt, tokenId: Uint256, data_len: felt, data: felt*
) -> (selector: felt) {
    let (beneficiary) = Beneficiary_address.read();
    let (this) = get_contract_address();
    let (caller) = get_caller_address();
    let (tx_info) = get_tx_info();
    let (nft_address) = NFT_address.read();

    with_attr error_message("caller is not DVNFT") {
        assert caller = nft_address;
    }

    // account_contract_address is always 0 (protostar limitation ?)
    // with_attr error_message("account_contract_address is not beneficiary") {
    //     assert beneficiary = tx_info.account_contract_address;
    // }

    with_attr error_message("invalid tokenId") {
        assert_uint256_le(tokenId, Uint256(5, 0));
    }

    let (token_owner) = IERC721.ownerOf(nft_address, tokenId);
    with_attr error_message("token not received") {
        assert token_owner = this;
    }

    let (received) = Received.read();
    Received.write(received + 1);

    let (received) = Received.read();
    if (received == 5) {
        let (token) = Token_address.read();

        IERC20.transfer(token, beneficiary, Uint256(169 * ONE, 0));

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return (selector=IERC721_RECEIVER_ID);
}
