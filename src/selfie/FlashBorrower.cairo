%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from contracts.interfaces.IERC3156FlashLender import IERC3156FlashLender

from contracts.interfaces.IERC3156FlashBorrower import IERC3156FlashBorrower

from openzeppelin.token.erc20.IERC20 import IERC20

from openzeppelin.security.safemath.library import SafeUint256

const SUCCESS = 1;
const FAILURE = 0;

@storage_var
func lender() -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_lender: felt) {
    lender.write(_lender);
    return ();
}

// Only consider to use a single flashLoan for the moment
@external
func onFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    initiator_address: felt,
    token_address: felt,
    amount: Uint256,
    fee: Uint256,
    calldata_len: felt,
    calldata: felt*,
) -> (return_code: felt) {
    let (caller_address: felt) = get_caller_address();
    with_attr error_message("FlashBorrower : untrust initiator") {
        assert caller_address = initiator_address;
    }
    let loan_type = [calldata];
    with_attr error_message("FlashLender: untrust loan type") {
        assert loan_type = 'single';
    }
    FlashBorrow(token_address, amount);
    return (return_code=SUCCESS);
}

func FlashBorrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt, amount: Uint256
) {
    alloc_locals;
    let (contract_address: felt) = get_contract_address();
    let (caller_address: felt) = get_caller_address();
    let (lender_contract: felt) = lender.read();
    let (allowance_: Uint256) = IERC20.allowance(lender_contract, lender_contract, caller_address);
    let (fee_: Uint256) = SafeUint256.mul(amount, Uint256(1, 0));
    let (repayement_amount: Uint256) = SafeUint256.add(amount, fee_);
    IERC20.approve(lender_contract, caller_address, repayement_amount);
    IERC3156FlashLender.flashLoan(contract_address, caller_address, token_address, amount);
    return ();
}
