// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDamnValuableNFT {
    func owner() -> (owner: felt) {
    }

    func renounceOwnership() {
    }

    func maxSupply() -> (maxSupply: felt) {
    }

    func totalSupply() -> (totalSupply: felt) {
    }

    // func safeMint(to: felt, tokenId: Uint256, data_len: felt, data: felt*, tokenURI: felt) {
    // }

    func mint(to: felt) {
    }
}
