%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from contracts.interfaces.IERC3156FlashLender import IERC3156FlashLender

from contracts.interfaces.IERC3156FlashBorrower import IERC3156FlashBorrower

from openzeppelin.token.erc20.IERC20 import IERC20

from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.access.ownable.library import Ownable

const SUCCESS = 1;
const FAILURE = 0;

@storage_var
func supported_token(token_address: felt) -> (bool: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner: felt) {
    Ownable.initializer(_owner);
    return ();
}

@view
func is_supported_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt
) -> (is_supported: felt) {
    let (is_supported: felt) = supported_token.read(token_address);
    return (is_supported,);
}

@view
func maxFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt
) -> (amount: Uint256) {
    let (supply: Uint256) = IERC20.totalSupply(token_address);
    return (supply,);
}

@view
func getFlashLoanFees{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt, amount: Uint256
) -> (fee: Uint256) {
    let (token_support: felt) = supported_token.read(token_address);
    with_attr error_message("Token is not supported") {
        assert token_support = 1;
    }
    let (fee_: Uint256) = _flashFee(token_address, amount);
    return (fee_,);
}

@external
func addSupportedToken{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    token: felt, price_feed: felt
) {
    Ownable.assert_only_owner();
    supported_token.write(token, 1);
    return ();
}

@external
func flashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    receiver: felt, token: felt, amount: Uint256
) -> (res: felt) {
    alloc_locals;
    let (contract_address: felt) = get_contract_address();
    let (caller_address: felt) = get_caller_address();
    let (supported_token_: felt) = supported_token.read(token);
    with_attr error_message("Token is not supported") {
        assert supported_token_ = 1;
    }
    let (fee: Uint256) = _flashFee(token, amount);
    let (transfer_status: felt) = IERC20.transfer(token, receiver, amount);
    with_attr error_message("Transfer failed") {
        assert transfer_status = SUCCESS;
    }
    let (calldata) = alloc();
    assert [calldata] = 'single';
    let (flash_loan_status: felt) = IERC3156FlashBorrower.onFlashLoan(
        contract_address, caller_address, token, amount, fee, 1, calldata
    );
    with_attr error_message("Flash loan failed") {
        assert flash_loan_status = SUCCESS;
    }
    let (amount_to_repay: Uint256) = SafeUint256.add(amount, fee);
    let (repay_status: felt) = IERC20.transferFrom(
        token, caller_address, contract_address, amount_to_repay
    );
    with_attr error_message("Fee transfer failed") {
        assert repay_status = SUCCESS;
    }
    return (SUCCESS,);
}

func _flashFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt, amount: Uint256
) -> (fee: Uint256) {
    let (contract_address: felt) = get_contract_address();
    let base_fees = Uint256(1, 0);
    let (total_amount: Uint256) = SafeUint256.mul(base_fees, amount);
    let (interest_amount: Uint256, _) = SafeUint256.div_rem(total_amount, Uint256(10000, 0));
    return (interest_amount,);
}
