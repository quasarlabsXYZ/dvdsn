%lang starknet

@contract_interface
namespace ISimpleGovernance {
    
    struct GovernanceAction {
        target: felt,
        value: Uint256,
        proposed_at: felt,
        executed_at: felt,
        data_len: felt,
        data: felt*
    }

    

}