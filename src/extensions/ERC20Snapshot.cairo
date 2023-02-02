%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_le,
    uint256_check,
    uint256_eq,
    assert_uint256_le,
)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_nn
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc20.library import ERC20

from src.utils.utils import findUpperBound

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
func _accountBalanceSnapshots(address: felt) -> (res: Snapshots) {
}

@storage_var
func _totalSupplySnapshots() -> (res: felt) {
}

@storage_var
func _currentSnapshotId() -> (res: Uint256) {
}

@event
func Snapshot(id: Uint256) {
}

namespace ERC20Snapshot {
    func _snapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        value: Uint256
    ) {
        _currentSnapshotId.write(_currentSnapshotId.read() + 1);
        let (currentId: Uint256) = _getCurrentSnapshotId();
        Snapshot.emit(currentId);
        return currentId;
    }

    func _getCurrentSnapshotId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> (value: Uint256) {
        return _currentSnapshotId.read();
    }

    func balanceOfAt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, snapshotId: Uint256
    ) -> (value: Uint256) {
        let (snapshotted: felt, val: Uint256) = _valueAt(
            snapshotId, _accountBalanceSnapshots.read(account)
        );
        if (snapshotted == 1) {
            return (value=val);
        } else {
            return (value=ERC20.balanceOf(account));
        }
    }

    func totalSupplyAt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        snapshotId: Uint256
    ) -> (value: Uint256) {
        let (snapshotted: felt, val: Uint256) = _valueAt(snapshotId, _totalSupplySnapshots.read());
        if (snapshotted == 1) {
            return (value=val);
        } else {
            return (value=ERC20.totalSupply());
        }
    }

    func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        recipient: felt, amount: Uint256
    ) -> (success: felt) {
        let (caller: felt) = get_caller_address();
        _updateAccountSnapshot(caller);
        _updateAccountSnapshot(recipient);
        return ERC20.transfer(recipient, amount);
    }

    func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, amount: Uint256
    ) -> (success: felt) {
        _updateAccountSnapshot(sender);
        _updateAccountSnapshot(recipient);
        return ERC20.transfer_from(sender, recipient, amount);
    }

    func _mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, amount: Uint256
    ) {
        Ownable.assert_only_owner();
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
        ERC20._mint(to, amount);
        return ();
    }

    func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) {
        let (caller) = get_caller_address();
        _updateAccountSnapshot(caller);
        _updateTotalSupplySnapshot();
        ERC20._burn(caller, amount);
        return ();
    }

    func burnFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt, amount: Uint256
    ) {
        let (caller) = get_caller_address();
        _updateAccountSnapshot(caller);
        _updateTotalSupplySnapshot();
        ERC20._spend_allowance(account, caller, amount);
        ERC20._burn(account, amount);
        return ();
    }

    func _valueAt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        snapshotId: Uint256, snapshots: Snapshots
    ) -> (boolean: felt, value: Uint256) {
        uint256_check(snapshotId);

        with_attr error_message("ERC20Snapshot: id is 0") {
            assert_uint256_lt(Uint256(0, 0), snapshotId);
        }

        with_attr error_message("ERC20Snapshot: nonexistent id") {
            assert_uint256_le(snapshotId, _getCurrentSnapshotId());
        }

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        let (index: Uint256) = findUpperBound(snapshots.ids_len, snapshots.ids, snapshotId);
        if (uint256_eq(index, snapshots.ids_len.read()) == 1) {
            return (FALSE, Uint256(0, 0));
        } else {
            return (TRUE, snapshots.values[index]);
        }
    }

    func _updateAccountSnapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt
    ) {
        _updateSnapshot(_accountBalanceSnapshots.read(account), ERC20.balanceOf(account));
    }

    func _updateTotalSupplySnapshot{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
        _updateSnapshot(_totalSupplySnapshots.read(), ERC20.totalSupply());
    }

    func _updateSnapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        snapshots: Snapshots, currentValue: Uint256
    ) {
        uint256_check(currentValue);

        let (currentId: Uint256) = _getCurrentSnapshotId();
        let (lastId: Uint256) = _lastSnapshotId(snapshots.ids);
        if (uint256_lt(lastId, currentId) == 1) {
            snapshots.ids_len.write(snapshots.ids_len + 1);
            snapshots.ids.write(snapshots.ids[snapshots.ids_len], currentId);
            snapshots.values_len.write(snapshots.values_len + 1);
            snapshots.values.write(snapshots.values[snapshots.values_len], currentValue);
        }
    }

    func _lastSnapshotId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ids_len: felt, ids: Uint256*
    ) -> (value: Uint256) {
        if (ids_len == 0) {
            return Uint256(0, 0);
        } else {
            return ids[ids_len - 1];
        }
    }
}
