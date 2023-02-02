%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IReceiverUnstoppable {
    func receive_tokens(token_address: felt, amount: Uint256) {
    }

    func execute_flash_loan(amount: Uint256) {
    }
}