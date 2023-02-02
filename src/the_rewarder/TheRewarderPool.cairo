%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_eq,
    uint256_signed_div_rem,
)
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
func liquidityToken() -> (address: felt) {
}

@storage_var
func accountingToken() -> (address: felt) {
}

@storage_var
func rewardToken() -> (address: felt) {
}

@storage_var
func lastSnapshotIdForRewards() -> (value: felt) {
}

@storage_var
func lastRecordedSnapshotTimestamp() -> (value: felt) {
}

@storage_var
func roundNumber() -> (value: felt) {
}

@storage_var
func lastRewardTimestamps(address: felt) -> (timestamp: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _liquidityToken: felt, accounting_class_hash: felt, reward_class_hash: felt
) {
    liquidityToken.write(_liquidityToken);

    let (accounting_address: felt) = deploy(
        class_hash=accounting_class_hash,
        contract_address_salt=0,
        constructor_calldata_size=3,
        constructor_calldata=cast(new (NAME, SYMBOL, 18), felt*),
        deploy_from_zero=FALSE,
    );
    accountingToken.write(accounting_address);

    let (reward_address: felt) = deploy(
        class_hash=reward_class_hash,
        contract_address_salt=1,
        constructor_calldata_size=0,
        constructor_calldata=0,
        deploy_from_zero=FALSE,
    );
    rewardToken.write(reward_address);

    _recordSnapshot();

    return ();
}

@external
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) {
    if (uint256_eq(amount, Uint256(0, 0)) == 1) {
        with_attr error_message("InvalidDepositAmount") {
            assert 1 = 0;
        }
    }
    let (caller: felt) = get_caller_address();

    IAccountingToken.mint(contract_address=accountingToken.read(), caller, amount);
    distributeRewards();
    let (this: felt) = get_contract_address();
    IERC20.transferFrom(contract_address=liquidityToken.read(), caller, this, amount);
}

@external
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) {
    let (caller: felt) = get_caller_address();
    IAccountingToken.burn(contract_address=accountingToken.read(), caller, amount);
    IERC20.transfer(contract_address=liquidityToken.read(), caller, amount);
}

@external
func distributeRewards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    rewards: Uint256
) {
    if (isNewRewardsRound() == TRUE) {
        _recordSnapshot();
    }
    let (caller: felt) = get_caller_address();
    let (totalDeposits: Uint256) = IAccountingToken.totalSupplyAt(
        contract_address=accountingToken.read(), lastSnapshotIdForRewards
    );
    let (amountDeposited: Uint256) = IAccountingToken.balanceOfAt(
        contract_address=accountingToken.read(), caller, lastSnapshotIdForRewards
    );
    if (uint256_lt(Uint256(0, 0), amountDeposited) == 1) {
        if (uint256_lt(Uint256(0, 0), totalDeposits) == 1) {
            let (product: Uint256) = uint256_mul(amountDeposited, Uint256(REWARDS, 0));
            // rounded down
            let (rewards: Uint256, _) = uint256_signed_div_rem(product, totalDeposits);
            if (uint256_lt(Uint256(0, 0), rewards) == 1) {
                if (_hasRetrievedReward(caller) == 0) {
                    IRewardToken.mint(contract_address=rewardToken.read(), caller, rewards);
                    let (block_timestamp: felt) = get_block_timestamp();
                    lastRewardTimestamps.write(caller, block_timestamp);
                }
            }
        }
    }
}

func _recordSnapshot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // lastSnapshotIdForRewards = uint128(accountingToken.snapshot());
    let (lastSnapshotIdForRewards: Uint256) = IAccountingToken.snapshot(
        contract_address=accountingToken.read()
    );
    lastRecordedSnapshotTimestamp.write(get_block_timestamp());
    roundNumber.write(roundNumber.read() + 1);
}

func _hasRetrievedReward{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (bool: felt) {
    if (is_le(lastRecordedSnapshotTimestamp.read(), lastRewardTimestamps.read(account)) == 1) {
        if (is_le(lastRewardTimestamps.read(account), lastRecordedSnapshotTimestamp.read() + REWARDS_ROUND_MIN_DURATION) == 1) {
            return TRUE;
        }
    } else {
        return FALSE;
    }
}
@view
func isNewRewardsRound{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    bool: felt
) {
    let (block_timestamp) = get_block_timestamp();
    let (lastRecorded: felt) = lastRecordedSnapshotTimestamp.read();
    if (is_le(lastRecorded + REWARDS_ROUND_MIN_DURATION, block_timestamp) == 1) {
        return TRUE;
    } else {
        return FALSE;
    }
}
