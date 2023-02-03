%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ITheRewarderPool {
    func deposit(amount: Uint256) {
    }

    func withdraw(amount: Uint256) {
    }

    func distributeRewards() -> (rewards: Uint256) {
    }

    func is_new_rewards_round() -> (bool: felt) {
    }
}
