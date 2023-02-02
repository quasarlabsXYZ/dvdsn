%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IUnstoppableLender {
    func depositTokens(amount: Uint256) {
    }

    func flashLoan(borrow_amount: Uint256) {
    }

    func setReceiverAddress(receiver_unstoppable: felt) {
    }
}
