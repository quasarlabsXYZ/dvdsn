%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFreeRiderNFTMarketplace {
    func get_NFT_address() -> (nft_address: felt) {
    }

    func get_Offers_count() -> (offers_count: felt) {
    }

    func offerMany(token_ids_len: felt, token_ids: Uint256*, price: Uint256) {
    }

    func buyMany(token_ids_len: felt, token_ids: Uint256*) {
    }
}
