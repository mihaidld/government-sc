// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Government.sol";

//contract Policy deployed at 0xCB77BC67287dE587366acc98da997C50d1925c2f

/* TODO: 
consider using Counter.Counter library
*/

contract Policy {
    //government contract token
    Government private _government;

    /// @dev struct Proposal to be voted by admins
    struct Proposal {
        string question; // proposal question
        string description; // proposal description
        uint256 counterForVotes; // counter of votes `Yes`
        uint256 counterAgainstVotes; // counter of votes `No`
        uint256 counterBlankVotes; // counter of votes `Blank`
    }

    /// @dev mapping from an id of proposal to a Proposal
    mapping(uint256 => Proposal) private _proposals;

    /// @dev counter for proposal id incremented by each proposal creation
    uint8 private _counterIdProposal;

    /// @dev mapping to check that an address can not vote twice for same proposal id
    mapping(address => mapping(uint8 => bool)) private _didVoteForProposal;

    /// @notice instructions to vote by admins: 0 -> Blank, 1 -> Yes, 2 -> No, other -> Invalid vote
    string public howToVote = "0 -> Blank, 1 -> Yes, 2 -> No";
    /// @dev vote options using enum type: 0 -> Option.Blank, 1 -> Option.Yes, 2 -> Option.No
    enum Option {Blank, Yes, No}

    /// @dev priceFull for 1 full CTZ (10^18 tokens) in wei : 10**16 or 0.01 ether or 10000000000000000
    constructor(address governmentAddress) public {
        _government = Government(governmentAddress);
    }

    /// @dev modifier to check if admin
    modifier onlyAdmin() {
        require(_government.citizen(msg.sender).termAdmin >= block.timestamp, "only admin can perform this action");
        _;
    }

    // Gets properties of a proposal
    function proposal(uint8 id) public view returns (Proposal memory) {
        return _proposals[id];
    }

    //For Admin : government affairs

    /// @dev function to propose new policy
    function proposePolicy(string memory policy, string memory description) public onlyAdmin {
        _counterIdProposal++;
        _proposals[_counterIdProposal] = Proposal(policy, description, 0, 0, 0);
    }

    /// @dev function to vote on policy proposals
    function votePolicy(uint8 id, Option voteOption) public onlyAdmin {
        require(_didVoteForProposal[msg.sender][id] == false, "admin already voted for this proposal");
        if (voteOption == Option.Blank) {
            _proposals[id].counterBlankVotes++;
        } else if (voteOption == Option.Yes) {
            _proposals[id].counterForVotes++;
        } else if (voteOption == Option.No) {
            _proposals[id].counterAgainstVotes++;
        } else revert("Invalid vote");
        _didVoteForProposal[msg.sender][id] = true;
    }
}
