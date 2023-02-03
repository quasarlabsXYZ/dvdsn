%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3156FlashBorrower {
    // * @dev Receive a flash loan.
    //  * @param initiator The initiator of the loan.
    //  * @param token The loan currency.
    //  * @param amount The amount of tokens lent.
    //  * @param fee The additional amount of tokens to repay.
    //  * @param data Arbitrary data structure, intended to contain user-defined parameters.
    //  * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
    func onFlashLoan(
        initiator_address: felt,
        token_address: felt,
        amount: Uint256,
        fee: Uint256,
        calldata_len: felt,
        calldata: felt*,
    ) -> (res: felt) {
    }
}
