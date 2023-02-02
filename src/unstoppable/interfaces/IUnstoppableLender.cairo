%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IUnstoppableLender {
    func deposit_tokens(amount: Uint256) {
    }

    func flash_loan(borrow_amount: Uint256) {
    }

    func set_receiver_unstoppable_address(receiver_unstoppable: felt) {
    }
}