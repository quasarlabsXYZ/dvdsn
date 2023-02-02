%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAccountingToken {
    func mint(to: felt, amount: Uint256) {
    }
    func burn(_from: felt, amount: Uint256) {
    }
    func snapshot() -> (value: Uint256) {
    }
    func totalSupplyAt(snapshotId: Uint256) -> (totalSupply: Uint256) {
    }
    func balanceOfAt(account: felt, snapshotId: Uint256) -> (value: Uint256) {
    }
}
