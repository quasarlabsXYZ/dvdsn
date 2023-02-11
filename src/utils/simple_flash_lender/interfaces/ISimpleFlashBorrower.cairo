%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ISimpleFlashBorrower {
    // * @dev Receive a flash loan.
    //  * @param initiator The initiator of the loan.
    //  * @param token The loan currency.
    //  * @param amount The amount of tokens lent.
    //  * @param fee The additional amount of tokens to repay.
    func onFlashLoan(
        initiator_address: felt, token_address: felt, amount: Uint256, fee: Uint256
    ) -> (res: felt) {
    }

    func flashBorrow(token_address: felt, amount: Uint256) {
    }
}
