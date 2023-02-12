%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc20.IERC20 import IERC20

from ERC3156_starknet.contracts.interfaces.IERC3156FlashLender import IERC3156FlashLender

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

@storage_var
func pool() -> (address: felt) {
}

@storage_var
func token() -> (address: felt) {
}

// * -------------------------------------------------------------------------- * //
// *                               Initialization                               * //
// * -------------------------------------------------------------------------- * //

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _pool: felt,
    _token: felt
) {
    pool.write(_pool);
    token.write(_token);

    return ();
}

// * -------------------------------------------------------------------------- * //
// *                                  Externals                                 * //
// * -------------------------------------------------------------------------- * //

@external
func onFlashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    initiator_address: felt,
    token_address: felt,
    amount: Uint256,
    fee: Uint256,
    calldata_len: felt,
    calldata: felt*
) -> (res:felt) {

  alloc_locals;

  let (local _pool)=  pool.read();
  with_attr error_message("Invalid initiator"){
        assert initiator_address = _pool;
  }

  let (local _token)=  token.read();
  with_attr error_message("Unsupported Token"){
        assert token_address = _token;
  }

  do_stuff_with_flash_loan_money();

  let (local amount_to_repay) = SafeUint256.add(amount, fee);
 
  IERC20.transfer(_token, _pool, amount_to_repay);

  return (res=1);
}

// Internal function where the funds received would be used
func do_stuff_with_flash_loan_money{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
   return ();
}
