// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
/* 
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";
import "./State.sol";

//contract Elections deployed at

contract Elections is Ownable {
    //national token
    Token private _token;

    //state contract token
    State private _state;

    uint256 private _currentMandateTerm;

    /// @dev mapping to check last date of vote (so an address can not vote twice during a mandate)
    mapping(address => uint256) private _dateVote;

    //constants
    uint8 constant MAJORITY_AGE = 18;
    uint8 constant NB_MINIMUM_VOTES_TO_GET_ELECTED = 5;
    uint256 constant MANDATE_DURATION = 8 weeks;
    uint256 constant ELECTIONS_DURATION = 1 weeks;
    uint8 constant RETIREMENT_AGE = 67;
    uint256 constant DENOMINATION = 10**18;
    uint256 constant STAKE_ADMIN = 100 * DENOMINATION;

    constructor(address tokenAddress, address stateAddress) public {
        _state = State(stateAddress);
        _token = Token(tokenAddress);
        transferOwnership(_state.sovereign());
    }

    /// @dev modifier to check if citizen has at least 1 unit of CTZ
    modifier onlySolventCitizens() {
        require(
            _state.citizen(msg.sender).nbOfCurrentAccountTokens > 0,
            "only citizens with at least 1 unit of CTZ in current account can perform this action"
        );
        _;
    }

    /// @dev modifier to check if citizen is not banned
    modifier onlyAllowedCitizens() {
        require(
            _state.citizen(msg.sender).termBanned < block.timestamp,
            "only citizens not banned can perform this action"
        );
        _;
    }

    /// @dev modifier to check is an address points to a citizen alive
    modifier onlyAliveCitizens() {
        require(_state.citizen(msg.sender).isAlive == true, "only citizens can perform this action");
        _;
    }

    /// @dev modifier to check if citizen's age is > 18
    modifier onlyAdults() {
        require(
            _state.citizen(msg.sender).retirementDate < (block.timestamp + (RETIREMENT_AGE - 18) * 52 weeks),
            "only adults can perform this action"
        );
        _;
    }

    // Gets date of the last election vote of a citizen
    function dateVote(address electorAddress) public view returns (uint256) {
        return _dateVote[electorAddress];
    }

    // Gets date of the end of current manadte following elections
    function currentMandateTerm() public view returns (uint256) {
        return _currentMandateTerm;
    }

    // Gets date of the moment
    function dateNow() public view returns (uint256) {
        return block.timestamp;
    }

    // Election stage

    /// @dev function for citizens to elect admins, election is possible during last week of current mandate term to insure continuity of public service
    function elect(address candidateAddress)
        public
        onlyAdults
        onlyAliveCitizens
        onlySolventCitizens
        onlyAllowedCitizens
    {
        require(
            _state.citizen(candidateAddress).retirementDate <
                block.timestamp + (RETIREMENT_AGE - MAJORITY_AGE) * 52 weeks,
            "only adults can be elected"
        );
        require(block.timestamp >= _currentMandateTerm - 1 weeks, "too early to elect");
        require(block.timestamp <= _currentMandateTerm, "too late to elect");
        require(
            _state.citizen(candidateAddress).nbOfCurrentAccountTokens >= STAKE_ADMIN,
            "candidate doesn't have enough CTZ to be elected"
        );
        require(_state.citizen(candidateAddress).isAlive == true, "candidate is not a citizen");
        require(_state.citizen(candidateAddress).termBanned < block.timestamp, "candidate is banned");
        require(
            _dateVote[msg.sender] < _currentMandateTerm - MANDATE_DURATION,
            "citizen already voted for this election"
        );
        _state.citizen(candidateAddress).nbVotes++;
        _dateVote[msg.sender] = block.timestamp;
    }

    /// @dev function for the sovereign to set new mandate term
    function updateMandate() public onlyOwner {
        _currentMandateTerm = block.timestamp + MANDATE_DURATION;
    }

    /// @dev function for the sovereign to name admins following election results after setting a new mandate term
    function setAdmin(address adminAddress) public onlyOwner {
        // require(
            _state.citizen(adminAddress).nbVotes >= NB_MINIMUM_VOTES_TO_GET_ELECTED,
            "candidate has not received the minimum number of votes"
        );
        require(
            _state.citizen(adminAddress).nbOfCurrentAccountTokens >= STAKE_ADMIN,
            "candidate doesn't have enough CTZ to be elected"
        );
        require(_state.citizen(adminAddress).isAlive == true, "candidate is not a citizen");
        require(_state.citizen(adminAddress).termBanned < block.timestamp, "candidate is banned");
        _state.updateCitizenTermAdmin(adminAddress, _currentMandateTerm);
        _state.updateCitizenNbVotes(adminAddress, 0); //reset to 0 number of votes
    }
}
 */
