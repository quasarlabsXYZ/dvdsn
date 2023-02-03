%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc


struct Votes {
    vote: felt,
    delegatedVote: felt,
    winner: felt,
}

@storage_var
func votes_storage(address: felt) -> (res: Votes){
}

@storage_var
func ownership() -> (res: felt){
}

func get_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(account : felt) -> (
        res : felt){
    let (res) = ownership.read();
    ownership.write(account);   
    return (res=res);
}

@view
func owners{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(account : felt) -> (
        res : felt){
    let (res) = get_owner(account);
    return (res=res);
}

@view
func array_demo(index : felt) -> (value : felt){
    // # Creates a pointer to the start of an array.
    let (my_array : felt*) = alloc();
    // # sets 3 as the value of the first element of the array
    assert [my_array] = 3;
    // # sets 15 as the value of the second element of the array
    assert [my_array + 1] = 15;
    // # sets index 2 to value 7.
    assert [my_array + 2] = 7;
    assert [my_array + 7] = 19;
    assert [my_array + 9] = 10;
    // # Access the list at the selected index.
    let value = my_array[index];
    return (value=value);
}

@external
func get_votes{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(index : felt){
    let(new_owner) = ownership.read();
    let (caller) = get_caller_address();
    assert caller = new_owner;
    let (indexing) = array_demo(index);
    assert indexing = 10;
    let vote_info = Votes(
    vote=10,
    delegatedVote=0,
    winner=0);
    let (vote_state) = votes_storage.read(caller);
    assert vote_state.delegatedVote = 0;
    assert vote_state.winner = 0;
    votes_storage.write(caller, vote_info);

    
    return ();
}

@external
func delegate{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(to : felt){
    let(new_owner) = ownership.read();
    let (caller) = get_caller_address();
    assert caller = new_owner;
    let (vote_state) = votes_storage.read(caller);
    let (addr_state) = votes_storage.read(to);
   
    assert addr_state.delegatedVote = 0;   
    assert vote_state.vote = 10;
    assert vote_state.winner = 0;
   
    let vote_info = Votes(
    vote=5,
    delegatedVote=5,
    winner=0);
    votes_storage.write(caller, vote_info);
    let (to_state) = votes_storage.read(to);
    votes_storage.write(to, Votes(vote=to_state.vote + 5, delegatedVote=to_state.delegatedVote, winner=to_state.winner));

    return ();
}

@external
func win{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(){
    let(new_owner) = ownership.read();
    let (caller) = get_caller_address();
    assert caller = new_owner;
    let (vote_state) = votes_storage.read(caller);
    assert vote_state.vote = 10;
    assert vote_state.delegatedVote = 5;
    votes_storage.write(caller, Votes(vote=vote_state.vote, delegatedVote=vote_state.delegatedVote, winner=caller));
    let (champ_state) = votes_storage.read(caller);
    assert champ_state.winner = caller;
   

    return ();
}