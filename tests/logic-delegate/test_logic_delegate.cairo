%lang starknet


from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address


from src.logic_delegate import Votes, votes_storage, ownership, get_owner, owners, array_demo,get_votes, delegate, win

@external
func test_array{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    let(out) = array_demo(9);
    assert out = 10;
    return ();

}

@external
func test_becomingOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    let (caller) = get_caller_address();
    owners(caller);
    let (new_owner) = ownership.read();
    assert caller = new_owner;
    return ();

}
@external
func test_getVotes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    let (caller) = get_caller_address();
    owners(caller);
    get_votes(9);
    let (voter_state) = votes_storage.read(caller);
    assert voter_state.vote = 10;
    return ();

}


@external
func test_delegate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    // let (to : felt) = alloc();
    local to: felt;
    // assert to = 111;
    let (caller) = get_caller_address();
    owners(caller);
    get_votes(9);
    
    delegate(caller);
    let (voter_state) = votes_storage.read(caller);
    assert voter_state.vote = 10;
    assert voter_state.delegatedVote = 5;
    return ();

}

@external
func test_Win{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    // let (to : felt) = alloc();
    local to: felt;
    // assert to = 111;
    let (caller) = get_caller_address();
    owners(caller);
    get_votes(9);
    
    delegate(caller);
    win();
    let (voter_state) = votes_storage.read(caller);
    assert voter_state.winner = caller;
    return ();

}

