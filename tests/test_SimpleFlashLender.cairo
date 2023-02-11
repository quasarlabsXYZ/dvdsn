%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, assert_uint256_eq
from starkware.cairo.common.alloc import alloc
from openzeppelin.security.safemath.library import SafeUint256

from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.token.erc20.IERC20 import IERC20

from src.utils.simple_flash_lender.interfaces.ISimpleFlashLender import ISimpleFlashLender
from src.utils.simple_flash_lender.interfaces.ISimpleFlashBorrower import ISimpleFlashBorrower

from openzeppelin.access.ownable.library import Ownable

const ONE = 10 ** 18;

@contract_interface
namespace IOwnable {
    func owner() -> (owner: felt) {
    }
}

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    tempvar admin = 'starknet-admin';
    tempvar DVT: felt;
    tempvar SIMPLE_FLASH_LENDER: felt;
    tempvar SIMPLE_FLASH_BORROWER: felt;

    %{
        context.admin = ids.admin
        context.DVT = deploy_contract("src/DamnValuableToken.cairo", [ids.admin]).contract_address
        context.SIMPLE_FLASH_LENDER = deploy_contract("src/utils/simple_flash_lender/SimpleFlashLender.cairo", [ids.admin]).contract_address
        context.SIMPLE_FLASH_BORROWER = deploy_contract("src/utils/simple_flash_lender/SimpleFlashBorrower.cairo", [context.SIMPLE_FLASH_LENDER]).contract_address
    %}

    %{
        ids.DVT = context.DVT
        ids.SIMPLE_FLASH_LENDER = context.SIMPLE_FLASH_LENDER
        ids.SIMPLE_FLASH_BORROWER = context.SIMPLE_FLASH_BORROWER
    %}

    %{ stop_prank = start_prank(ids.admin, target_contract_address=ids.DVT) %}
    // send 1000 DVT SIMPLE_FLASH_LENDER
    IERC20.transfer(DVT, SIMPLE_FLASH_LENDER, Uint256(1000 * ONE, 0));
    // send 10 DVT SIMPLE_FLASH_BORROWER
    IERC20.transfer(DVT, SIMPLE_FLASH_BORROWER, Uint256(10 * ONE, 0));
    %{ stop_prank() %}

    return ();
}

@external
func test_SimpleFlashLender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    check_initialization();
    check_addSupportedToken();
    check_flashLoan();

    return ();
}

func check_initialization{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local admin: felt;
    local DVT: felt;
    local SIMPLE_FLASH_LENDER: felt;
    local SIMPLE_FLASH_BORROWER: felt;

    %{
        ids.admin = context.admin
        ids.DVT = context.DVT
        ids.SIMPLE_FLASH_LENDER = context.SIMPLE_FLASH_LENDER
        ids.SIMPLE_FLASH_BORROWER = context.SIMPLE_FLASH_BORROWER
    %}

    let (lender_balance) = IERC20.balanceOf(DVT, SIMPLE_FLASH_LENDER);
    assert_uint256_eq(lender_balance, Uint256(1000 * ONE, 0));

    let (borrower_balance) = IERC20.balanceOf(DVT, SIMPLE_FLASH_BORROWER);
    assert_uint256_eq(borrower_balance, Uint256(10 * ONE, 0));

    return ();
}

func check_addSupportedToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar DVT: felt;
    tempvar SIMPLE_FLASH_LENDER: felt;
    tempvar admin: felt;

    %{
        ids.admin = context.admin
        ids.DVT = context.DVT
        ids.SIMPLE_FLASH_LENDER = context.SIMPLE_FLASH_LENDER
    %}

    let (local owner) = IOwnable.owner(SIMPLE_FLASH_LENDER);

    let (is_supported_before: felt) = ISimpleFlashLender.is_supported_token(
        SIMPLE_FLASH_LENDER, DVT
    );
    assert is_supported_before = 0;

    %{ stop_prank = start_prank(ids.admin, target_contract_address=ids.SIMPLE_FLASH_LENDER) %}
    ISimpleFlashLender.addSupportedToken(SIMPLE_FLASH_LENDER, DVT);
    %{ stop_prank() %}

    let (is_supported: felt) = ISimpleFlashLender.is_supported_token(SIMPLE_FLASH_LENDER, DVT);
    assert is_supported = 1;

    return ();
}

func check_flashLoan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local admin: felt;
    local DVT: felt;
    local SIMPLE_FLASH_LENDER: felt;
    local SIMPLE_FLASH_BORROWER: felt;

    %{
        ids.admin = context.admin
        ids.DVT = context.DVT
        ids.SIMPLE_FLASH_LENDER = context.SIMPLE_FLASH_LENDER
        ids.SIMPLE_FLASH_BORROWER = context.SIMPLE_FLASH_BORROWER
    %}

    let (local max_amount: Uint256) = ISimpleFlashLender.maxFlashLoan(SIMPLE_FLASH_LENDER, DVT);
    let (local fees: Uint256) = ISimpleFlashLender.getFlashLoanFees(
        SIMPLE_FLASH_LENDER, DVT, max_amount
    );

    let (lender_balance_before) = IERC20.balanceOf(DVT, SIMPLE_FLASH_LENDER);
    let (borrower_balance_before) = IERC20.balanceOf(DVT, SIMPLE_FLASH_BORROWER);

    ISimpleFlashBorrower.flashBorrow(SIMPLE_FLASH_BORROWER, DVT, max_amount);

    let (lender_balance_after) = IERC20.balanceOf(DVT, SIMPLE_FLASH_LENDER);
    let (borrower_balance_after) = IERC20.balanceOf(DVT, SIMPLE_FLASH_BORROWER);

    let (lender_balance_after_calc) = SafeUint256.add(lender_balance_before, fees);
    let (borrower_balance_after_calc) = SafeUint256.sub_le(borrower_balance_before, fees);

    assert_uint256_eq(lender_balance_after, lender_balance_after_calc);
    assert_uint256_eq(borrower_balance_after, borrower_balance_after_calc);

    return ();
}
