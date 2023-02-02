%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IReceiverUnstoppable {
    func receiveTokens(token_address: felt, amount: Uint256) {
    }

    func executeFlashLoan(amount: Uint256) {
    }
}
