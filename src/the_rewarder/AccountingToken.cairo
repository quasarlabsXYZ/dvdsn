%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_eq, uint256_not
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc20.library import ERC20
from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.utils.constants.library import UINT8_MAX
from openzeppelin.security.safemath.library import SafeUint256

from src.extensions.ERC20Snapshot import ERC20Snapshot

const MINTER_ROLE = 0;
const SNAPSHOT_ROLE = 1;
const BURNER_ROLE = 2;

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, decimals: felt
) {
    let (caller: felt) = get_caller_address();
    ERC20.name.write(name);
    ERC20.symbol.write(symbol);
    with_attr error_message("ERC20: decimals exceed 2^8") {
        assert_le(decimals, UINT8_MAX);
    }
    ERC20.decimals.write(decimals);
    Ownable.initializer(caller);
    AccessControl.initializer();
    AccessControl.grant_role(MINTER_ROLE, caller);
    AccessControl.grant_role(SNAPSHOT_ROLE, caller);
    AccessControl.grant_role(BURNER_ROLE, caller);
    return ();
}

//
// ERC20Snapshot custom functions
//

@view
func totalSupplyAt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    snapshotId: Uint256
) -> (totalSupply: Uint256) {
    let (totalSupply: Uint256) = ERC20Snapshot.totalSupplyAt(snapshotId);
    return (totalSupply=totalSupply);
}

@view
func balanceOfAt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, snapshotId: Uint256
) -> (value: Uint256) {
    let (value: Uint256) = ERC20Snapshot.balanceOfAt(account, snapshotId);
    return (value=value);
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, amount: Uint256
) {
    AccessControl.assert_only_role(MINTER_ROLE);
    ERC20Snapshot.mint(to, amount);
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, amount: Uint256
) {
    AccessControl.assert_only_role(BURNER_ROLE);
    ERC20Snapshot.burn(_from, amount);
}

@external
func snapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    value: Uint256
) {
    AccessControl.assert_only_role(SNAPSHOT_ROLE);
    return ERC20Snapshot._snapshot();
}

//
// ERC20 functions
//

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC20.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC20.symbol();
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC20.total_supply();
    return (totalSupply=totalSupply);
}

@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    return ERC20.decimals();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    return ERC20.balance_of(account);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

@view
func has_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, user: felt
) -> (has_role: felt) {
    return AccessControl.has_role(role, user);
}

@view
func get_role_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt
) -> (admin: felt) {
    return AccessControl.get_role_admin(role);
}

@external
func grant_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, user: felt
) {
    AccessControl.grant_role(role, user);
    return ();
}

@external
func revoke_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, user: felt
) {
    AccessControl.revoke_role(role, user);
    return ();
}

@external
func renounce_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    role: felt, user: felt
) {
    AccessControl.renounce_role(role, user);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}
