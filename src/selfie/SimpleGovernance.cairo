%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

// * -------------------------------------------------------------------------- * //
// *                                   Events                                   * //
// * -------------------------------------------------------------------------- * //

@event
func ActionQueued(action_id: felt, caller: felt) {
}

@event
func ActionExecuted(action_id: felt, caller: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                                   Structs                                  * //
// * -------------------------------------------------------------------------- * //

struct GovernanceAction {
    target: felt,
    value: Uint256,
    proposed_at: felt,
    executed_at: felt,
    data_len: felt,
    data: felt*
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

@storage_var
func _actions(_action_counter: felt) -> (action: GovernanceAction) {
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
    calldata: felt*
) -> (action_id: Uint256) {
    
}

@external
func execute_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    action_id: felt
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

