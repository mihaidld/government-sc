// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./Government.sol";

//contract Government deployed at 0x2600378267A97f0C24dCa3d70F98d1E461dCe560
//contract Proposal deployed at 0x9f16B106Ebe2D849c22845d06609415Ada2791b6

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
    constructor(address governmentAddress_) public {
        _government = Government(governmentAddress_);
    }

    /// @dev modifier to check if admin
    modifier onlyAdmin() {
        require(_government.citizen(msg.sender).termAdmin >= block.timestamp, "only admin can perform this action");
        _;
    }

    // Gets properties of a proposal
    function proposal(uint8 _id) public view returns (Proposal memory) {
        return _proposals[_id];
    }

    //For Admin : government affairs

    /// @dev function to propose new policy
    function proposePolicy(string memory _policy, string memory _description) public onlyAdmin {
        _counterIdProposal++;
        _proposals[_counterIdProposal] = Proposal(_policy, _description, 0, 0, 0);
    }

    /// @dev function to vote on policy proposals
    function votePolicy(uint8 _id, Option _voteOption) public onlyAdmin {
        require(_didVoteForProposal[msg.sender][_id] == false, "admin already voted for this proposal");
        if (_voteOption == Option.Blank) {
            _proposals[_id].counterBlankVotes++;
        } else if (_voteOption == Option.Yes) {
            _proposals[_id].counterForVotes++;
        } else if (_voteOption == Option.No) {
            _proposals[_id].counterAgainstVotes++;
        } else revert("Invalid vote");
        _didVoteForProposal[msg.sender][_id] = true;
    }
}
