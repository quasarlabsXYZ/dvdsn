%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ITrusterLenderPool {
    func flashLoan(
        amount: Uint256,
        borrower: felt,
        target: felt,
        selector: felt,
        calldata_len: felt,
        calldata: felt*
    ) -> (block_timestamp: felt) {
    }
}