%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPuppetPool {
    func borrow(amount: Uint256, recipant: felt) {
    }

    func calculateDepositRequired(amount: Uint256) -> (depositRequired: Uint256) {
    }
}
