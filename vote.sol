pragma solidity ^0.4.19;
contract Ballot {

    struct Voter {
        uint weight;
        uint voted;
        uint vote;
        address delegate;
    }
    
    struct Proposal {
        uint voteCount;
    }

    address chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;

    /// Create a new ballot with $(_numProposals) different proposals.
    function Ballot(uint _numProposals) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        proposals.length = _numProposals;
    }
    
    function get_chairperson_address() public constant returns(address) {
        return chairperson;
    }
    
    function get_nb_proposals() public constant returns(uint) {
        return proposals.length;
    }
    
    function get_my_voting_weight() public constant returns(uint) {
        return voters[msg.sender].weight;
    }
    
    function get_voting_weight(address _voter) public isAdmin() constant returns(uint) {
        return voters[_voter].weight;
    }

    /// Give $(toVoter) the right to vote on this ballot.
    /// May only be called by $(chairperson).
    function giveRightToVote(address toVoter) public {
        if (msg.sender != chairperson || voters[toVoter].voted!=0) return;
        voters[toVoter].weight = 1;
    }
    
    modifier isAdmin() {
        if (msg.sender != chairperson) revert();
        _;
    }
    
    modifier hasnotdelegated(address to) {
        if (voters[to].delegate != address(0)) revert();
        _;
    }
    
    modifier hasnotvoted() { // The sender can't launch the function if he has voted already
        if (voters[msg.sender].voted != 0) revert();
        _;
    }
    
    /// Delegate your vote to the voter $(to).
    function delegate(address to) public hasnotdelegated(to) hasnotvoted() {
        Voter storage sender = voters[msg.sender]; // assigns reference
        if (sender.voted!=0) return; // You can't delegate if you have already voted
        if (to == msg.sender) return; ///You can't delegate to yourself
        sender.voted = 1;
        sender.delegate = to;
        Voter storage delegateTo = voters[to];
        if (delegateTo.voted!=0)
            proposals[delegateTo.vote].voteCount += sender.weight;
        else
            delegateTo.weight += sender.weight;
    }

    /// Give a single vote to proposal $(toProposal).
    function vote(uint toProposal) public {
        Voter storage sender = voters[msg.sender];
        if (sender.voted!=0 || toProposal >= proposals.length) return;
        sender.voted = 1;
        sender.vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
    }

    function winningProposal() public constant returns (uint _winningProposal, uint _voteCount) {
        uint winningVoteCount = 0;
        for (uint prop = 0; prop < proposals.length; prop++) {
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
                _voteCount = winningVoteCount;
            }
        }
    }
    
    function Kill() public isAdmin() {
        delete chairperson;
        delete proposals;
        delete voters;
        selfdestruct(msg.sender);
    }
}