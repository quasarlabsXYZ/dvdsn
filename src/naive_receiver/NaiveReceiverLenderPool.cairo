%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (Uint256, uint256_lt)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.alloc import alloc

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc20.IERC20 import IERC20

from ERC3156_starknet.contracts.interfaces.IERC3156FlashBorrower import IERC3156FlashBorrower

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

const SUCCESS = 1;
const FAILURE = 0;

// 1 DVT
const FEES = 1 * 10**18;

@storage_var
func token() -> (address: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token : felt
) {
    token.write(_token);
    return ();
}

@view
func maxFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt
) -> (max: Uint256) {
    let (_token) = token.read();
    let (contract_address) = get_contract_address();
    if( token_address == _token ) {
        let ( balance: Uint256 ) = IERC20.balanceOf(token_address, contract_address);
        return (max=balance);
    }
    return (max=Uint256(0,0));
}


@view
func flashFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt
) -> (fees: Uint256) {
    let (_token) = token.read();
   
    with_attr error_message("Unsupported Currency"){
        assert token_address = _token;
    }

    return (fees=Uint256(FEES,0));
}


@external
func flashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
     receiver: felt,
     token_address: felt,
     amount: Uint256
 ) -> (res: felt) {

    alloc_locals;

    let (local _token) = token.read();
    with_attr error_message("Unsupported Token"){
        assert token_address = _token;
    }

    let (contract_address: felt) = get_contract_address();
    let (caller_address: felt) = get_caller_address();

    let (balance_before: Uint256) = IERC20.balanceOf(_token, contract_address);

    //send token to receiver
    let (transfer_status: felt) = IERC20.transfer(_token, receiver, amount);
    with_attr error_message("Transfer failed") {
        assert transfer_status = SUCCESS;
    }

    let (fee: Uint256) = flashFee(_token);
    let (calldata) = alloc();
    assert [calldata] = '0';
    let calldata_len = 1;
   
    //call receiver onFlashLoan
    let (flash_loan_status: felt) = IERC3156FlashBorrower.onFlashLoan(
        receiver, contract_address, token_address, amount, fee, calldata_len, calldata
    );
    with_attr error_message("Flash loan failed") {
        assert flash_loan_status = SUCCESS;
    }

    let (balance_after: Uint256) = IERC20.balanceOf(token_address, contract_address);
    let (min_balance_after: Uint256) = SafeUint256.add(balance_before, fee);

    let (not_repayed) = uint256_lt(balance_after , min_balance_after);
    with_attr error_message("Repay Failed"){
        assert not_repayed = 0;
    }
    
    return (res=SUCCESS);
}
