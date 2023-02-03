%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_eq,
    uint256_signed_div_rem,
    uint256_lt,
    uint256_mul,
)

from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    deploy,
    get_contract_address,
)

from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_le

from starkware.cairo.common.bool import TRUE, FALSE

from src.the_rewarder.interfaces.IAccountingToken import IAccountingToken
from src.the_rewarder.interfaces.IRewardToken import IRewardToken
from src.the_rewarder.interfaces.IERC20 import IERC20

const REWARDS_ROUND_MIN_DURATION = 5 * 24 * 60 * 60;
const REWARDS = 100 * 10 ** 18;

const NAME = 'rToken';
const SYMBOL = 'rTKN';

@storage_var
func liquidity_token() -> (address: felt) {
}

@storage_var
func accounting_token() -> (address: felt) {
}

@storage_var
func reward_token() -> (address: felt) {
}

@storage_var
func last_snapshot_id_for_rewards() -> (value: felt) {
}

@storage_var
func last_recorded_snapshot_timestamp() -> (value: felt) {
}

@storage_var
func round_number() -> (value: felt) {
}

@storage_var
func last_reward_timestamps(address: felt) -> (timestamp: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _liquidity_token: felt, accounting_class_hash: felt, reward_class_hash: felt
) {
    liquidity_token.write(_liquidity_token);
    let (ctor_calldata) = alloc();
    let (accounting_address: felt) = deploy(
        class_hash=accounting_class_hash,
        contract_address_salt=0,
        constructor_calldata_size=3,
        constructor_calldata=cast(new (NAME, SYMBOL, 18), felt*),
        deploy_from_zero=FALSE,
    );
    accounting_token.write(accounting_address);

    let (reward_address: felt) = deploy(
        class_hash=reward_class_hash,
        contract_address_salt=1,
        constructor_calldata_size=0,
        constructor_calldata=ctor_calldata,
        deploy_from_zero=FALSE,
    );
    reward_token.write(reward_address);

    _record_snapshot();

    return ();
}

@external
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) {
    alloc_locals;
    let (local res: felt) = uint256_eq(amount, Uint256(0, 0));
    if (res == 1) {
        with_attr error_message("InvalidDepositAmount") {
            assert 1 = 0;
        }
    }
    let (local caller: felt) = get_caller_address();
    let (local accounting_address: felt) = accounting_token.read();

    IAccountingToken.mint(contract_address=accounting_address, to=caller, amount=amount);
    distributeRewards();
    let (local this: felt) = get_contract_address();
    let (local token_address: felt) = liquidity_token.read();
    IERC20.transferFrom(
        contract_address=token_address, sender=caller, recipient=this, amount=amount
    );
    return ();
}

@external
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) {
    alloc_locals;
    let (local caller: felt) = get_caller_address();
    let (local accounting_address: felt) = accounting_token.read();
    let (local token_address: felt) = liquidity_token.read();

    IAccountingToken.burn(contract_address=accounting_address, _from=caller, amount=amount);
    IERC20.transfer(contract_address=token_address, recipient=caller, amount=amount);
    return ();
}

@external
func distributeRewards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    rewards: Uint256
) {
    alloc_locals;
    let (local accounting_address: felt) = accounting_token.read();
    let (local token_address: felt) = liquidity_token.read();
    let (local reward_address: felt) = reward_token.read();

    let (local boolean: felt) = is_new_rewards_round();
    if (boolean == TRUE) {
        _record_snapshot();
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    let (caller: felt) = get_caller_address();
    let (totalDeposits: Uint256) = IAccountingToken.total_supply_at(
        contract_address=accounting_address, last_snapshot_id_for_rewards
    );
    let (amountDeposited: Uint256) = IAccountingToken.balance_of_at(
        contract_address=accounting_address,
        account=caller,
        snapshot_id=last_snapshot_id_for_rewards,
    );
    let (res: felt) = uint256_lt(Uint256(0, 0), amountDeposited);
    if (res == 1) {
        if (uint256_lt(Uint256(0, 0), totalDeposits) == 1) {
            let (product: Uint256, _) = uint256_mul(amountDeposited, Uint256(REWARDS, 0));
            // rounded down
            let (rewards: Uint256, _) = uint256_signed_div_rem(product, totalDeposits);
            if (uint256_lt(Uint256(0, 0), rewards) == 1) {
                if (_has_retrieved_reward(caller) == 0) {
                    IRewardToken.mint(contract_address=reward_address, to=caller, amount=rewards);
                    let (block_timestamp: felt) = get_block_timestamp();
                    last_reward_timestamps.write(caller, block_timestamp);
                }
            }
        }
    }
    return ();
}

func _record_snapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (last_snapshot_id_for_rewards: Uint256) = IAccountingToken.snapshot(
        contract_address=accounting_token.read()
    );
    last_recorded_snapshot_timestamp.write(get_block_timestamp());
    round_number.write(round_number.read() + 1);
    return ();
}

func _has_retrieved_reward{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (bool: felt) {
    if (is_le(last_recorded_snapshot_timestamp.read(), last_reward_timestamps.read(account)) == 1) {
        if (is_le(last_reward_timestamps.read(account), last_recorded_snapshot_timestamp.read() + REWARDS_ROUND_MIN_DURATION) == 1) {
            return TRUE;
        }
    } else {
        return FALSE;
    }
}
@view
func is_new_rewards_round{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    bool: felt
) {
    let (block_timestamp) = get_block_timestamp();
    let (lastRecorded: felt) = last_recorded_snapshot_timestamp.read();
    if (is_le(lastRecorded + REWARDS_ROUND_MIN_DURATION, block_timestamp) == 1) {
        return TRUE;
    } else {
        return FALSE;
    }
}
