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
    func has_role(role: felt, user: felt) -> (has_role: felt) {
    }
    func balance_of(account: felt) -> (balance: Uint256) {
    }
}
