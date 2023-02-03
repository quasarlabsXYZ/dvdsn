%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_eq, uint256_not
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc20.library import ERC20, ERC20_name, ERC20_decimals, ERC20_symbol
from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.security.safemath.library import SafeUint256

from src.extensions.ERC20Snapshot import ERC20Snapshot

const MINTER_ROLE = 1;
const SNAPSHOT_ROLE = 2;
const BURNER_ROLE = 3;
const ADMIN_ROLE = 0;

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, decimals: felt
) {
    alloc_locals;
    ERC20_name.write(name);
    ERC20_symbol.write(symbol);
    let (caller: felt) = get_caller_address();
    ERC20_decimals.write(decimals);
    Ownable.initializer(caller);
    AccessControl.initializer();
    AccessControl._grant_role(ADMIN_ROLE, caller);
    AccessControl._grant_role(MINTER_ROLE, caller);
    AccessControl._grant_role(SNAPSHOT_ROLE, caller);
    AccessControl._grant_role(BURNER_ROLE, caller);
    return ();
}

//
// ERC20Snapshot custom functions
//

@view
func total_supply_at{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    snapshot_id: Uint256
) -> (total_supply: Uint256) {
    let (total_supply: Uint256) = ERC20Snapshot.total_supply_at(snapshot_id);
    return (total_supply=total_supply);
}

@view
func balance_of_at{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, snapshot_id: Uint256
) -> (value: Uint256) {
    let (value: Uint256) = ERC20Snapshot.balance_of_at(account, snapshot_id);
    return (value=value);
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, amount: Uint256
) {
    AccessControl.assert_only_role(MINTER_ROLE);
    ERC20Snapshot._mint(to, amount);
    return ();
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, amount: Uint256
) {
    AccessControl.assert_only_role(BURNER_ROLE);
    ERC20Snapshot._burn(amount);
    return ();
}

@external
func snapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    supply: Uint256, balance: Uint256
) {
    alloc_locals;
    AccessControl.assert_only_role(SNAPSHOT_ROLE);
    let (local supply_id: Uint256) = ERC20Snapshot._snapshot_supply();
    let (local balance_id: Uint256) = ERC20Snapshot._snapshot_balances();
    return (supply=supply_id, balance=balance_id);
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
func total_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    total_supply: Uint256
) {
    let (total_supply: Uint256) = ERC20.total_supply();
    return (total_supply=total_supply);
}

@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    return ERC20.decimals();
}

@view
func balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
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
