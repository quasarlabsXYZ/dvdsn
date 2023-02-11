// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_lt
from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.token.erc20.IERC20 import IERC20

from starkware.starknet.common.syscalls import get_contract_address, get_caller_address

from starkware.cairo.common.alloc import alloc

from src.naive_receiver.interface.IERC3156FlashBorrower import IERC3156FlashBorrower

const SUCCESS = 1;
const FAILURE = 0;

// 1 DVT
const FEES = 1 * 10 ** 18;

@storage_var
func DVT_address() -> (address: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    dvt_address: felt
) {
    DVT_address.write(dvt_address);
    return ();
}

@view
func maxFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) -> (
    max: Uint256
) {
    let (dvt_address) = DVT_address.read();
    let (contract_address) = get_contract_address();
    if (token == dvt_address) {
        let (balance: Uint256) = IERC20.balanceOf(token, contract_address);
        return (max=balance);
    }
    return (max=Uint256(0, 0));
}

@view
func flashFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) -> (
    fees: Uint256
) {
    let (dvt_address) = DVT_address.read();

    with_attr error_message("Unsupported Currency") {
        assert token = dvt_address;
    }
    return (fees=Uint256(FEES, 0));
}

@external
func flashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    receiver: felt, token: felt, amount: Uint256
) -> (res: felt) {
    alloc_locals;

    let (local dvt_address) = DVT_address.read();
    with_attr error_message("Unsupported Token") {
        assert token = dvt_address;
    }

    let (contract_address: felt) = get_contract_address();
    let (caller_address: felt) = get_caller_address();

    let (balance_before: Uint256) = IERC20.balanceOf(dvt_address, contract_address);

    // send token to receiver
    let (transfer_status: felt) = IERC20.transfer(token, receiver, amount);
    with_attr error_message("Transfer failed") {
        assert transfer_status = SUCCESS;
    }

    let (fee: Uint256) = flashFee(token);
    let (calldata) = alloc();
    assert [calldata] = '0';
    let calldata_len = 1;

    // call receiver onFlashLoan
    let (flash_loan_status: felt) = IERC3156FlashBorrower.onFlashLoan(
        receiver, contract_address, token, amount, fee, calldata_len, calldata
    );
    with_attr error_message("Flash loan failed") {
        assert flash_loan_status = SUCCESS;
    }

    let (balance_after: Uint256) = IERC20.balanceOf(dvt_address, contract_address);
    let (min_balance_after: Uint256) = SafeUint256.add(balance_before, fee);

    let (not_repayed) = uint256_lt(balance_after, min_balance_after);
    with_attr error_message("Repay Failed") {
        assert not_repayed = 0;
    }

    return (res=SUCCESS);
}
