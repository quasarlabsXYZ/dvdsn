%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAccountingToken {
    func mint(to: felt, amount: Uint256) {
    }
    func burn(_from: felt, amount: Uint256) {
    }
    func snapshot() -> (supply: Uint256, balance: Uint256) {
    }
    func total_supply_at(snapshot_id: Uint256) -> (total_supply: Uint256) {
    }
    func balance_of_at(account: felt, snapshot_id: Uint256) -> (value: Uint256) {
    }
}
