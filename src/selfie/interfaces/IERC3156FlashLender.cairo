%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3156FlashLender {
    // * @dev The amount of currency available to be lended.
    // * @param address of token you want to borrow .
    // * @return The maximum amount of `token` that can be borrowed.

    func maxFlashLoan(token_address: felt) -> (max_amount: Uint256) {
    }

    // * @dev The fee to be charged for a given loan.
    //  * @param token The loan currency.
    //  * @param amount The amount of tokens lent.
    //  * @return The amount of `token` to be charged for the loan, on top of the returned principal.
    func flashFee(token_address: felt, amount: Uint256) -> (fee: Uint256) {
    }

    // * @dev Initiate a flash loan.
    //  * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
    //  * @param token The loan currency.
    //  * @param amount The amount of tokens lent.
    //  * @param data Arbitrary data structure, intended to contain user-defined parameters.
    func flashLoan(receiver: felt, token_address: felt, amount: Uint256) -> (success: felt) {
    }

    func is_supported_token(token_address: felt) -> (is_supported: felt) {
    }
}
