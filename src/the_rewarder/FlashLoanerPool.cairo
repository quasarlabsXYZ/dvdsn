%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_eq,
    uint256_signed_div_rem,
    uint256_lt,
    assert_uint256_lt,
)
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    deploy,
    get_contract_address,
    call_contract,
)

from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_le

from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from src.the_rewarder.interfaces.IAccountingToken import IAccountingToken
from src.the_rewarder.interfaces.IRewardToken import IRewardToken
from src.the_rewarder.interfaces.IERC20 import IERC20

struct Call {
    to: felt,
    selector: felt,
    calldata_len: felt,
    calldata: felt*,
}

// const RECEIVE_FLASHLOAN_SELECTOR = 147888053196246221552724878847108733894168897053278161494098725433913990908;

@storage_var
func liquidityToken() -> (address: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _liquidityToken: felt
) {
    liquidityToken.write(_liquidityToken);
    return ();
}

@external
func flashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) {
    ReentrancyGuard.start();
    let (this: felt) = get_contract_address();
    let token_address: felt = liquidityToken.read();

    let (balance_before: Uint256) = IERC20.balanceOf(contract_address=token_address, account=this);
    with_attr error_message("NotEnoughTokenBalance") {
        assert_uint256_lt(balance_before, amount);
    }
    let caller: felt = get_caller_address();
    IERC20.transfer(contract_address=token_address, recipient=caller, amount=amount);
    // selector is get_selector_from_name("receiveFlashLoan")
    let res = call_contract(
        contract_address=caller,
        function_selector=147888053196246221552724878847108733894168897053278161494098725433913990908,
        calldata_size=2,
        calldata=cast(new (amount.low, amount.high), felt*),
    );

    let (balance_after: Uint256) = IERC20.balanceOf(contract_address=token_address, account=this);

    let (balance_dif: felt) = uint256_lt(balance_after, balance_before);
    if (balance_dif == 1) {
        with_attr error_message("NotEnoughTokenBalance") {
            assert 1 = 0;
        }
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    ReentrancyGuard.end();
    return ();
}
