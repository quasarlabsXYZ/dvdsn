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
const REWARDS = 100;

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
func last_snapshot_id_for_rewards() -> (value: Uint256) {
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
    let (accounting_address: felt) = deploy(
        class_hash=accounting_class_hash,
        contract_address_salt=0,
        constructor_calldata_size=3,
        constructor_calldata=cast(new (NAME, SYMBOL, 18), felt*),
        deploy_from_zero=FALSE,
    );
    accounting_token.write(accounting_address);
    let (empty_calldata) = alloc();
    let (reward_address: felt) = deploy(
        class_hash=reward_class_hash,
        contract_address_salt=1,
        constructor_calldata_size=0,
        constructor_calldata=empty_calldata,
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

    let (boolean: felt) = is_new_rewards_round();
    if (boolean == 1) {
        _record_snapshot();
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    let (accounting_address: felt) = accounting_token.read();
    let (last_id: Uint256) = last_snapshot_id_for_rewards.read();
    let (total_deposits: Uint256) = IAccountingToken.total_supply_at(
        contract_address=accounting_address, snapshot_id=last_id
    );
    let (local caller: felt) = get_caller_address();
    let (amount_deposited: Uint256) = IAccountingToken.balance_of_at(
        contract_address=accounting_address, account=caller, snapshot_id=last_id
    );
    let rewards: Uint256 = Uint256(0, 0);
    let (product: Uint256, _) = uint256_mul(amount_deposited, Uint256(REWARDS, 0));
    let (rewards_amount: Uint256, _) = uint256_signed_div_rem(product, total_deposits);

    let reward_address: felt = reward_token.read();
    let (block_timestamp: felt) = get_block_timestamp();
    let (is_deposited_nz: felt) = uint256_lt(Uint256(0, 0), amount_deposited);
    let (are_deposits_nz: felt) = uint256_lt(Uint256(0, 0), total_deposits);
    let (are_rewards_nz: felt) = uint256_lt(Uint256(0, 0), rewards_amount);
    let (has_retrieved: felt) = _has_retrieved_reward(caller);
    if (is_deposited_nz == 1) {
        if (are_deposits_nz == 1) {
            if (are_rewards_nz == 1) {
                if (has_retrieved == 0) {
                    IRewardToken.mint(
                        contract_address=reward_address, to=caller, amount=rewards_amount
                    );
                    last_reward_timestamps.write(caller, block_timestamp);
                } else {
                    tempvar syscall_ptr: felt* = syscall_ptr;
                    tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                }
            } else {
                tempvar syscall_ptr: felt* = syscall_ptr;
                tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            }
            return (rewards=rewards_amount);
        } else {
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    return (rewards=Uint256(0, 0));
}

func _record_snapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (accounting_address: felt) = accounting_token.read();
    let (snapshot_id_supply: Uint256, snapshot_id_balance: Uint256) = IAccountingToken.snapshot(
        contract_address=accounting_address
    );
    last_snapshot_id_for_rewards.write(snapshot_id_balance);
    let (timestamp: felt) = get_block_timestamp();
    last_recorded_snapshot_timestamp.write(timestamp);

    let (local number: felt) = round_number.read();
    local sum = number + 1;
    round_number.write(sum);
    return ();
}

func _has_retrieved_reward{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (bool: felt) {
    let (last_reward) = last_reward_timestamps.read(account);
    let (last_recorded) = last_recorded_snapshot_timestamp.read();

    let res: felt = is_le(last_recorded, last_reward);
    if (res == 1) {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        let res2: felt = is_le(last_reward, last_recorded + REWARDS_ROUND_MIN_DURATION);
        if (res2 == 1) {
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            return (bool=TRUE);
        }
    }
    return (bool=FALSE);
}
@view
func is_new_rewards_round{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    bool: felt
) {
    let (block_timestamp) = get_block_timestamp();
    let (lastRecorded: felt) = last_recorded_snapshot_timestamp.read();
    let res: felt = is_le(lastRecorded + REWARDS_ROUND_MIN_DURATION, block_timestamp);
    if (res == 1) {
        return (bool=TRUE);
    }
    return (bool=FALSE);
}
