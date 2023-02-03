%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFlashLoanerPool {
    func flashLoan(amount: Uint256) {
    }
}
