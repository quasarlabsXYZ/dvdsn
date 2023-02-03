%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.access.ownable.library import Ownable

from src.selfie.extensions.ERC20Snapshot import ERC20Snapshot
from src.selfie.interfaces.IERC3156FlashBorrower import IERC3156FlashBorrower

// * -------------------------------------------------------------------------- * //
// *                                   Events                                   * //
// * -------------------------------------------------------------------------- * //

@event
func FundsDrained(receiver: felt, amount: Uint256) {
}

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

@storage_var
func _token() -> (res: felt) {
}

@storage_var
func simple_governance() -> (res: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt,
    governance: felt
) {
    _token.write(token);
    simple_governance.write(governance); 
    return ();
}

// * -------------------------------------------------------------------------- * //
// *                               Functions                                    * //
// * -------------------------------------------------------------------------- * //

@view
func max_flash_loan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _flash_loan_token: felt
) -> (balance: Uint256) {
    let (token) = _token.read();
    let (contract) = get_contract_address();
    let zero: Uint256 = Uint256(0, 0);
    if (token == _flash_loan_token) {
        let balance = IERC20.balanceOf(token, contract);
        return (balance);
    }
    return (balance=zero);
}

@view
func flash_fee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _flash_loan_token: felt
) -> (res: Uint256) {
    let (token) = _token.read();
    let zero = Uint256(0, 0);
    with_attr error_message("Unsupported Currency") {
        assert _flash_loan_token = token;
    }
    return (res=zero);
}

@external
func flash_loan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _receiver: felt,
    _flash_loan_token: felt,
    _amount: Uint256,
    calldata_len: felt,
    calldata: felt*
) -> (res: felt) {
    alloc_locals;
    ReentrancyGuard.start();
    let (local token) = _token.read();
    let (caller) = get_caller_address();

    // Ensure token is supported
    with_attr error_message("Unsupported Currency") {
        assert _flash_loan_token = token;
    }

    // transfer token
    IERC20.transfer(token, _receiver, _amount);
    // with_attr error_message("Callback failed") {
    // // should return keccak of: "ERC3156FlashBorrower.onFlashLoan"
    //         assert IERC3156FlashBorrower.onFlashLoan(caller, _token, _amount, 0, calldata_len, calldata)
    // }

    with_attr error_message("Repay failed") {
        IERC20.transferFrom(token, _receiver, caller, _amount);
    }

    ReentrancyGuard.end();
    return (res=1);    
}

@external
func emergency_exit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    receiver: felt
) {
    //only Governance can call
    let (caller) = get_caller_address();
    let (token) = _token.read();
    let (amount) = IERC20.balanceOf(token, caller);
    IERC20.transfer(token, receiver, amount);

    //emit funds drained
    FundsDrained.emit(receiver, amount);

    return ();
}
