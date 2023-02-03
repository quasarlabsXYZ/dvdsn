// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.token.erc20.IERC20 import IERC20

from src.naive_receiver.interface.IERC3156FlashLender import IERC3156FlashLender

from starkware.starknet.common.syscalls import (
    get_contract_address,
)

@storage_var
func Pool_address() -> (pool: felt) {
}

@storage_var
func Token_address() -> (pool: felt) {
}


@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pool: felt,
 token: felt) {
    Pool_address.write(pool);
    Token_address.write(token);
    return ();
}

@external
func onFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    initiator_address: felt,
    token_address: felt,
    amount: Uint256,
    fee: Uint256,
    calldata_len: felt,
    calldata: felt*
) -> (res:felt){

  alloc_locals;

  let (local pool_address)=  Pool_address.read();
  with_attr error_message("Invalid initiator"){
        assert initiator_address = pool_address;
  }

  let (local _token_address)=  Token_address.read();
  with_attr error_message("Unsupported Token"){
        assert token_address = _token_address;
  }

  do_stuff_with_flash_loan_money();

  let (local amount_to_repay) = SafeUint256.add(amount,fee);
 
  IERC20.transfer(_token_address,pool_address,amount_to_repay);

  return (res=1);
}

// Internal function where the funds received would be used
func do_stuff_with_flash_loan_money{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
   return ();
}

  