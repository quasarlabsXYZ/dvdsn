%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_le,
    uint256_check,
    uint256_eq,
    assert_uint256_le,
    assert_uint256_lt,
    uint256_add,
)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_nn
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc20.library import ERC20
from openzeppelin.access.ownable.library import Ownable

// from src.utils.utils import findUpperBound

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                   * //
// * -------------------------------------------------------------------------- * //

struct Snapshots {
    ids_len: felt,
    ids: Uint256*,
    values_len: felt,
    values: Uint256*,
}

@storage_var
func ids(index: felt) -> (value: felt) {
}

@storage_var
func _account_balance_snapshots(snapshot_id: Uint256, address: felt) -> (balance: Uint256) {
}

@storage_var
func _account_balance_last_snapshot_id() -> (id: Uint256) {
}

@storage_var
func _total_supply_snapshots(snapshot_id: Uint256) -> (total_supply: Uint256) {
}

@storage_var
func _total_supply_last_snapshot_id() -> (id: Uint256) {
}

@event
func SnapshotBalance(id: Uint256) {
}

@event
func SnapshotSupply(id: Uint256) {
}

namespace ERC20Snapshot {
    func _snapshot_balances{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        value: Uint256
    ) {
        alloc_locals;

        let (last_id: Uint256) = _account_balance_last_snapshot_id.read();
        let (sum: Uint256, _) = uint256_add(last_id, Uint256(1, 0));

        _account_balance_last_snapshot_id.write(sum);
        let (current_id: Uint256) = _get_current_balance_snapshot_id();
        tempvar syscall_ptr: felt* = syscall_ptr;
        SnapshotBalance.emit(current_id);
        return (value=current_id);
    }

    func _snapshot_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        value: Uint256
    ) {
        alloc_locals;

        let (last_id: Uint256) = _total_supply_last_snapshot_id.read();
        let (sum: Uint256, _) = uint256_add(last_id, Uint256(1, 0));
        _total_supply_last_snapshot_id.write(sum);
        let (current_id: Uint256) = _get_current_supply_snapshot_id();
        tempvar syscall_ptr: felt* = syscall_ptr;
        SnapshotSupply.emit(current_id);
        return (value=current_id);
    }

    func _snapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        (value_balance: Uint256, value_supply: Uint256),
    ) {
        let (current_balance_snapshot_id: Uint256) = _snapshot_balances();
        let (current_supply_snapshot_id: Uint256) = _snapshot_supply();
        return (current_balance_snapshot_id, current_supply_snapshot_id);
    }

    func _get_last_balance_snapshot_id{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (value: Uint256) {
        let (res: Uint256) = _account_balance_last_snapshot_id.read();
        return (value=res);
    }

    func _get_last_total_supply_snapshot_id{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (value: Uint256) {
        let (res: Uint256) = _total_supply_last_snapshot_id.read();
        return (value=res);
    }

    func _get_current_supply_snapshot_id{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (current: Uint256) {
        let (res: Uint256) = _get_last_total_supply_snapshot_id();

        let (sum: Uint256, _) = uint256_add(res, Uint256(1, 0));

        return (current=sum);
    }

    func _get_current_balance_snapshot_id{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (current: Uint256) {
        let (res: Uint256) = _get_last_balance_snapshot_id();
        let (sum: Uint256, _) = uint256_add(res, Uint256(1, 0));

        return (current=sum);
    }

    func balance_of_at{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, snapshot_id: Uint256
    ) -> (value: Uint256) {
        with_attr error_message("ERC20Snapshot: id is 0") {
            assert_uint256_lt(Uint256(0, 0), snapshot_id);
        }
        let (current: Uint256) = _get_current_balance_snapshot_id();

        with_attr error_message("ERC20Snapshot: nonexistent id") {
            assert_uint256_le(snapshot_id, current);
        }

        let (val: Uint256) = _account_balance_snapshots.read(snapshot_id, account);

        return (value=val);
    }

    func total_supply_at{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        snapshot_id: Uint256
    ) -> (value: Uint256) {
        with_attr error_message("ERC20Snapshot: id is 0") {
            assert_uint256_lt(Uint256(0, 0), snapshot_id);
        }
        let (current: Uint256) = _get_current_supply_snapshot_id();
        with_attr error_message("ERC20Snapshot: nonexistent id") {
            assert_uint256_le(snapshot_id, current);
        }

        let (val: Uint256) = _total_supply_snapshots.read(snapshot_id);

        return (value=val);
    }

    func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        recipient: felt, amount: Uint256
    ) -> (success: felt) {
        let (caller: felt) = get_caller_address();
        _update_account_snapshot(caller);
        _update_account_snapshot(recipient);
        return ERC20.transfer(recipient, amount);
    }

    func transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, amount: Uint256
    ) -> (success: felt) {
        _update_account_snapshot(sender);
        _update_account_snapshot(recipient);
        return ERC20.transfer_from(sender, recipient, amount);
    }

    func _mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, amount: Uint256
    ) {
        Ownable.assert_only_owner();
        _update_account_snapshot(to);
        _update_total_supply_snapshot();
        ERC20._mint(to, amount);
        return ();
    }

    func _burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) {
        alloc_locals;
        let (local caller: felt) = get_caller_address();
        _update_account_snapshot(caller);
        _update_total_supply_snapshot();
        ERC20._burn(caller, amount);
        return ();
    }

    func _burn_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, amount: Uint256
    ) {
        let (caller) = get_caller_address();
        _update_account_snapshot(caller);
        _update_total_supply_snapshot();
        ERC20._spend_allowance(account, caller, amount);
        ERC20._burn(account, amount);
        return ();
    }

    func _update_account_snapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt
    ) {
        alloc_locals;
        // local syscall_ptr: felt* = syscall_ptr;

        let (current_id: Uint256) = _get_current_balance_snapshot_id();
        let (last_id: Uint256) = _get_last_balance_snapshot_id();
        let (res: felt) = uint256_lt(last_id, current_id);

        if (res == 1) {
            let (balance: Uint256) = ERC20.balance_of(account);
            _account_balance_snapshots.write(current_id, account, balance);
            _account_balance_last_snapshot_id.write(current_id);
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        return ();
    }

    func _update_total_supply_snapshot{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
        alloc_locals;
        // local syscall_ptr: felt* = syscall_ptr;

        let (current_id: Uint256) = _get_current_balance_snapshot_id();
        let (last_id: Uint256) = _get_last_total_supply_snapshot_id();
        let (res: felt) = uint256_lt(last_id, current_id);

        if (res == 1) {
            let (total_supply: Uint256) = ERC20.total_supply();

            _total_supply_snapshots.write(current_id, total_supply);
            _total_supply_last_snapshot_id.write(current_id);
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        return ();
    }
}