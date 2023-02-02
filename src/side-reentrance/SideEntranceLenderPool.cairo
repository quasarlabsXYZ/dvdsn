%lang starknet
from starkware.cairo.common.math import assert_nn, assert_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_add, assert_uint256_eq, uint256_sub
from openzeppelin.token.erc20.library import ERC20

@contract_interface
namespace IDAMN {
    func transfer(to_address: felt, value: Uint256) {
    }

    func transferFrom(from_address: felt, to_address: felt, value: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (res: Uint256) {
    }

    func balanceOf(user: felt) -> (res: Uint256) {
    }
}

@contract_interface
namespace IFlashLoanReceiver {
    func execute(value: Uint256) {
    }
}


@storage_var
func _poolBalance() -> (res: Uint256) {
}
@storage_var
func _userBalance(account: felt) -> (res: Uint256) {
}

@storage_var
func _damnValuableToken() -> (res: felt) {
}

@storage_var
func _receiverUnstoppable() -> (res: felt) {
}

@view
func damnValuableToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = _damnValuableToken.read();
    return (res,);
}

@view
func pool_Balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: Uint256) {
    let (res) = _poolBalance.read();
    return (res,);
}

@view
func userBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account:felt) -> (res: Uint256) {
    let (res) = _userBalance.read(account);
    return (res,);
}
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    damnValuableToken: felt
) {
    assert_not_zero(damnValuableToken);
    _damnValuableToken.write(damnValuableToken);

    return ();
}

@external
func depositTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256,
) {

    let zero_as_uint256: Uint256 = Uint256(0, 0);
    let (amnt) = uint256_le(amount, zero_as_uint256);
    if (amnt == 1){
        return();
        }
    // let amount = Uint256(low=amount_low, high=amount_high);
    let (damn) = _damnValuableToken.read();
    let (caller) = get_caller_address();
    let (contract_address) = get_contract_address();
    IDAMN.transferFrom(damn, caller, contract_address, amount);
    let (res) = _poolBalance.read();
    let (usr) = _userBalance.read(caller);
    let (newBalance, _) = uint256_add(res, amount);
    let (newUsrBal, _) = uint256_add(usr, amount);
    _poolBalance.write(newBalance);
    _userBalance.write(caller, newUsrBal);
    return ();   
}

@external
func withdrawTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {

    let (damn) = _damnValuableToken.read();
    let (caller) = get_caller_address();
    let (contract_address) = get_contract_address();
    
    let (res) = _poolBalance.read();
    let (usr) = _userBalance.read(caller);
    let (newBalance) = uint256_sub(res, usr);
    let (newUsrBal) = uint256_sub(usr, usr);
    _poolBalance.write(newBalance);
    _userBalance.write(caller, newUsrBal);
    return ();   
}

@external
func flashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(borrowAmount: Uint256
) {
    let (damn) = _damnValuableToken.read();
    let (caller) = get_caller_address();
    let (contract_address) = get_contract_address();
    let (balanceBefore) = IDAMN.balanceOf(damn, contract_address);
    IDAMN.transfer(damn, caller, borrowAmount);
  
    IFlashLoanReceiver.execute(caller, borrowAmount);
    let (balanceAfter) = IDAMN.balanceOf(damn, contract_address);
    let (balance_check) = uint256_le(balanceBefore, balanceAfter);
    assert balance_check = 1;
    return ();
    

}

