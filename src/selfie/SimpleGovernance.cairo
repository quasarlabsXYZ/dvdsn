%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_unsigned_div_rem, uint256_sub, uint256_signed_nn
from openzeppelin.token.erc20.IERC20 import IERC20
from src.selfie.extensions.ERC20Snapshot import ERC20Snapshot
from starkware.cairo.common.math import unsigned_div_rem, assert_lt
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

// * -------------------------------------------------------------------------- * //
// *                                   Events                                   * //
// * -------------------------------------------------------------------------- * //

@event
func ActionQueued(action_id: Uint256, caller: felt) {
}

@event
func ActionExecuted(action_id: Uint256, caller: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                                   Structs                                  * //
// * -------------------------------------------------------------------------- * //

struct GovernanceAction {
    Target: felt,
    Value: Uint256,
    ProposedAt: felt,
    ExecutedAt: felt,
    DataLen: felt,
    Data: felt,
}

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

@storage_var
func _governance_token() -> (res: felt) {
}

@storage_var
func _action_counter() -> (res: felt) {
}

@storage_var
func _action_delay_in_seconds() -> (res: felt) {
}

//indexed list of all GovernanceAction
@storage_var
func _actions(_action_counter: felt) -> (action: GovernanceAction) {
}

//indexed list of all calldata
@storage_var
func calldata(idx: felt) -> (data: felt) {

}

// * -------------------------------------------------------------------------- * //
// *                                   Constructor                              * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
    }(governance_token: felt) {
    _governance_token.write(governance_token);
    _action_counter.write(1);

    // 2 days in seconds
    _action_delay_in_seconds.write(172800);
    return ();
}

@external
func queue_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    target: felt,
    value: Uint256,
    calldata_len: felt,
    calldata: felt
) -> (action_id: Uint256) {
    alloc_locals;
    let (caller) = get_caller_address();
    let (enough_votes) = _has_enough_votes(caller);
    let (action_counter) = _action_counter.read();
    let (block_timestamp) = get_block_timestamp();
    let action_id: Uint256 = Uint256(0, 0);

    with_attr error_message("Insufficient votes") {
        assert_lt(0, enough_votes);
    }

    with_attr error_message("Invalid target") {
        assert target = caller;
    }

    with_attr error_message("Target must have code") {
        assert_lt(0, calldata_len);
    }

    action_id = Uint256(action_counter, 0);

    let ga = GovernanceAction(target, value, block_timestamp, 0, calldata_len + 1, calldata);
    _actions.write(action_counter + 1, ga);
    _action_counter.write(action_counter + 1);

    ActionQueued.emit(action_id, caller);
    return action_id;

}

@external
func execute_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    action_id: Uint256
) {
}

@view
func get_action_delay{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (action_delay_in_seconds: felt) {
    let (action_delay_in_seconds) = _action_delay_in_seconds.read();
    return action_delay_in_seconds;
}

@view
func get_governance_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (address: felt) {
    let (governance_token) = _governance_token.read();
    return governance_token;
}

@view
func get_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (governance_action: GovernanceAction) {

}

@view
func get_action_counter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (action_counter: felt
) {
    let (action_counter) = _action_counter.read();
    return action_counter;
}

func _can_be_executed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    action_id: Uint256) -> (success: felt
) {
    let (local action_to_execute: GovernanceAction) = _actions(action_id); // get action_id index in actions array

    if (action_to_execute.ProposedAt == 0) {
        return 0;
    }

    let (block_timestamp) = get_block_timestamp;
    let (time_delta) = block_timestamp - action_to_execute.ProposedAt;
    let (action_delay_in_seconds) = _action_delay_in_seconds.read();

    if (action_to_execute.ExecutedAt == 0) {
        return (1);
    } else {
        return (0);
    }
}

func _has_enough_votes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    who: felt
) -> (res: felt) {
    let (last_balance: Uint256) = ERC20Snapshot._get_last_balance_snapshot_id();
    let (total_supply: Uint256) = ERC20Snapshot._snapshot_supply();
    let (half_total_supply: Uint256, _) = uint256_unsigned_div_rem(total_supply, Uint256(2, 0));
    let (is_larger) = uint256_sub(last_balance, half_total_supply);
    let is_nn = uint256_signed_nn(is_larger);

    return is_nn;
}
