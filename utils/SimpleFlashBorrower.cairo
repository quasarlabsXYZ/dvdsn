%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from utils.interfaces.ISimpleFlashLender import ISimpleFlashLender
from utils.interfaces.ISimpleFlashBorrower import ISimpleFlashBorrower

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

@external
func onFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    initiator_address: felt,
    token_address: felt,
    amount: Uint256,
    fee: Uint256
) -> (return_code: felt) {

    let (caller_address: felt) = get_caller_address();
    with_attr error_message("flashBorrow : untrust initiator") {
        assert caller_address = initiator_address;
    }
   
    // do stuff with token address borrowed
   
    return (return_code=SUCCESS);
}

@external
func flashBorrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt, amount: Uint256
) {

    alloc_locals;
    let (contract_address: felt) = get_contract_address();
    let (lender_contract: felt) = lender.read();
    //let (allowance_: Uint256) = IERC20.allowance(lender_contract, lender_contract, caller_address);
    let (fee_: Uint256) = ISimpleFlashLender.getFlashLoanFees(lender_contract, token_address,amount);
    let (repayement_amount: Uint256) = SafeUint256.add(amount, fee_);

    IERC20.approve(token_address, lender_contract, repayement_amount);
    ISimpleFlashLender.flashLoan(lender_contract, contract_address, token_address, amount);
    return ();
}
