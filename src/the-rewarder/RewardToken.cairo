%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.token.erc20.library import ERC20
from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.access.ownable.library import Ownable

const MINTER_ROLE = 0;
const NAME = 'Reward Token';
const SYMBOL = 'RWT';
const DECIMALS = 18;

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller: felt) = get_caller_address();
    Ownable.initializer(caller);
    ERC20.initializer(NAME, SYMBOL, DECIMALS);
    AccessControl.initializer();
    AccessControl.grant_role(MINTER_ROLE, caller);
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, amount: Uint256
) {
    AccessControl.assert_only_role(MINTER_ROLE);
    ERC20._mint(to, amount);
}
