// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./CitizenERC20.sol";

/// @author Mihai Doldur
/// @title A government contract for a token economy

//contract Government deployed at 0xb591cbF1008888E0b17CDfAe56Be2eDA4929d15e

/* TODO: 
import and use SafeMath
import Ownable / Access Control from OZ to replace onlyOwner?
Modular : move Policy and Punishment variables & functions to the other contracts
Test : test every function, require, modifier
emit Events for state changes (ex. UpdatedCitizen or specific event for each change ChangedHealth, ChosenAdmin etc.)
add NatSpec comments

*/
contract Government {
    // Variables of state

    //address of the sovereign
    address payable private _sovereign;

    //national token
    CitizenERC20 private _token;

    // price of 1 full CTZ (10^18 units of token) in wei;
    uint256 private _price;

    uint256 private _currentMandateTerm;

    /// @dev struct Citizen
    struct Citizen {
        bool isAlive; //true, after death false (the sovereign gets his balance)
        address employer; //company employing the citizen
        bool isWorking; //set by an admin
        bool isSick; //set by an admin
        uint256 nbVotes; //during elections increased if candidate receives votes. If >= 5 named admin and nbVotes is reset to 0
        uint256 termAdmin; // till when a citizen is an admin (8 weeks from election)
        uint256 retirementDate;
        uint256 termBanned; // till when is the member banned following punishment for treason: block.timestamp + 10 * 52 * 1 weeks
        uint256 nbOfCurrentAccountTokens; //100 full tokens (100 * 10**18 at registration), can be increased by salaries
        uint256 nbOfHealthInsuranceTokens; //10% from each salary, acces to it when admins declares him sick
        uint256 nbOfUnemploymentTokens; //10% from each salary, acces to it when admins declares him unemployed
        uint256 nbOfRetirementTokens; //10% from each salary, acces to it when age 67
    }

    /// @dev mapping from an address to a Citizen
    mapping(address => Citizen) private _citizens;

    /// @dev mapping to check last date of vote (so an address can not vote twice during a mandate)
    mapping(address => uint256) private _dateVote;

    //constants
    uint8 constant RETIREMENT_AGE = 67;
    uint8 constant MAJORITY_AGE = 18;
    uint256 constant MANDATE_DURATION = 8 weeks;
    uint256 constant ELECTIONS_DURATION = 1 weeks;
    uint8 constant NB_MINIMUM_VOTES_TO_GET_ELECTED = 5;
    uint256 constant DENOMINATION = 10**18;
    uint256 constant SMALL_PUNISHMENT = 5 * DENOMINATION;
    uint256 constant MODERATE_PUNISHMENT = 50 * DENOMINATION;
    uint256 constant SERIOUS_PUNISHMENT = 100 * DENOMINATION;
    uint256 constant AWARD_CITIZENSHIP = 100 * DENOMINATION;
    uint256 constant STAKE_ADMIN = 100 * DENOMINATION;
    uint256 constant BANISHMENT = 10 * 52 weeks;

    /// @notice options to be voted by admins: 0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason, other -> Invalid choice
    string public howToPunish = "0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason";
    /// @dev punishment options using enum type: 0 -> Punishment.Small, 1 -> Punishment.Moderate, 2 -> Punishment.Serious, 3 -> Punishment.Treason
    enum Punishment {Small, Moderate, Serious, Treason}

    /// @notice instructions to change health status by admins: 0 -> Died, 1 -> Healthy, 2 -> Sick, other -> Invalid choice
    string public healthStatusOptions = "0 -> Died, 1 -> Healthy, 2 -> Sick";
    /// @dev health status options using enum type: 0 -> HealthStatus.Died, 1 -> HealthStatus.Healthy, 2 -> HealthStatus.Sick
    enum HealthStatus {Died, Healthy, Sick}

    // Emitted when a citizen property changes
    event UpdatedCitizen(
        address indexed citizen,
        bool isAlive,
        address employer,
        bool isWorking,
        bool isSick,
        uint256 nbVotes,
        uint256 termAdmin,
        uint256 retirementDate,
        uint256 termBanned,
        uint256 nbOfCurrentAccountTokens,
        uint256 nbOfHealthInsuranceTokens,
        uint256 nbOfUnemploymentTokens,
        uint256 nbOfRetirementTokens
    );

    /// @dev priceFull for 1 full CTZ (10^18 tokens) in wei : 10**16 or 0.01 ether or 10000000000000000
    constructor(address tokenAddress, uint256 priceFull) public {
        _token = CitizenERC20(tokenAddress);
        _price = priceFull;
        _sovereign = _token.getOwner(); // sovereign;
    }

    //Modifiers

    // A modifier for checking if the msg.sender is the sovereign (e.g. president, king)
    modifier onlySovereign() {
        require(msg.sender == _sovereign, "ERC20: Only sovereign can perform this action");
        _;
    }

    /// @dev modifier to check if admin
    modifier onlyAdmin() {
        require(_citizens[msg.sender].termAdmin >= block.timestamp, "only admin can perform this action");
        _;
    }

    /// @dev modifier to check if citizen has at least 1 unit of CTZ
    modifier onlySolventCitizens() {
        require(
            _citizens[msg.sender].nbOfCurrentAccountTokens > 0,
            "only citizens with at least 1 unit of CTZ in current account can perform this action"
        );
        _;
    }

    /// @dev modifier to check if citizen is not banned
    modifier onlyAllowedCitizens() {
        require(_citizens[msg.sender].termBanned < block.timestamp, "only citizens not banned can perform this action");
        _;
    }

    /// @dev modifier to check is an address points to a citizen alive
    modifier onlyAliveCitizens() {
        require(_citizens[msg.sender].isAlive == true, "only citizens can perform this action");
        _;
    }
    /// @dev modifier to check if citizen's age is > 18
    modifier onlyAdults() {
        require(
            _citizens[msg.sender].retirementDate < (block.timestamp + (RETIREMENT_AGE - 18) * 52 weeks),
            "only adults can perform this action"
        );
        _;
    }

    //Getter functions yo view private variables

    // Returns the properties of a citizen
    function citizen(address citizenAddress) public view returns (Citizen memory) {
        return _citizens[citizenAddress];
    }

    // Get address of deployed token contract
    function tokenAddress() public view returns (CitizenERC20) {
        return _token;
    }

    // Get address of sovereign (STATE)
    function sovereign() public view returns (address payable) {
        return _sovereign;
    }

    // Gets price of 1 full CTZ (10^18 units of token) in wei
    function price() public view returns (uint256) {
        return _price;
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
            _citizens[candidateAddress].retirementDate < block.timestamp + (RETIREMENT_AGE - MAJORITY_AGE) * 52 weeks,
            "only adults can be elected"
        );
        require(block.timestamp >= _currentMandateTerm - 1 weeks, "too early to elect");
        require(block.timestamp <= _currentMandateTerm, "too late to elect");
        require(
            _citizens[candidateAddress].nbOfCurrentAccountTokens >= STAKE_ADMIN,
            "candidate doesn't have enough CTZ to be elected"
        );
        require(_citizens[candidateAddress].isAlive == true, "candidate is not a citizen");
        require(_citizens[candidateAddress].termBanned < block.timestamp, "candidate is banned");
        require(
            _dateVote[msg.sender] < _currentMandateTerm - MANDATE_DURATION,
            "citizen already voted for this election"
        );
        _citizens[candidateAddress].nbVotes++;
        _dateVote[msg.sender] = block.timestamp;
    }

    /// @dev function for the sovereign to set new mandate term
    function updateMandate() public onlySovereign {
        _currentMandateTerm = block.timestamp + MANDATE_DURATION;
    }

    /// @dev function for the sovereign to name admins following election results after setting a new mandate term
    function setAdmin(address adminAddress) public onlySovereign {
        require(
            _citizens[adminAddress].nbVotes >= NB_MINIMUM_VOTES_TO_GET_ELECTED,
            "candidate has not received the minimum number of votes"
        );
        require(
            _citizens[adminAddress].nbOfCurrentAccountTokens >= STAKE_ADMIN,
            "candidate doesn't have enough CTZ to be elected"
        );
        require(_citizens[adminAddress].isAlive == true, "candidate is not a citizen");
        require(_citizens[adminAddress].termBanned < block.timestamp, "candidate is banned");
        _citizens[adminAddress].termAdmin = _currentMandateTerm;
        _citizens[adminAddress].nbVotes = 0; //reset to 0 number of votes
    }

    /// @dev function to give sentences
    function punish(address sentenced, Punishment option) public onlyAdmin {
        /// @dev addresses of sovereign and not a citizen cannot be punished
        require(sentenced != _sovereign, "sovereign cannot be punished");
        require(_citizens[sentenced].isAlive == true, "impossible punishment: not an alive citizen");
        uint256 _currentBalance = _citizens[sentenced].nbOfCurrentAccountTokens;
        if (option == Punishment.Small) {
            _currentBalance = _currentBalance > SMALL_PUNISHMENT ? _currentBalance - SMALL_PUNISHMENT : 0;
        } else if (option == Punishment.Moderate) {
            _currentBalance = _currentBalance > MODERATE_PUNISHMENT ? _currentBalance - MODERATE_PUNISHMENT : 0;
        } else if (option == Punishment.Serious) {
            _currentBalance = _currentBalance > SERIOUS_PUNISHMENT ? _currentBalance - SERIOUS_PUNISHMENT : 0;
        } else if (option == Punishment.Treason) {
            _currentBalance = 0;
            _citizens[sentenced].nbOfHealthInsuranceTokens = 0;
            _citizens[sentenced].nbOfUnemploymentTokens = 0;
            _citizens[sentenced].nbOfRetirementTokens = 0;
            _citizens[sentenced].termBanned = block.timestamp + BANISHMENT;
            _token.transferFrom(sentenced, _sovereign, _token.balanceOf(sentenced));
            //if the citizen is an admin
            if (_citizens[sentenced].termAdmin > block.timestamp) {
                _citizens[sentenced].termAdmin = block.timestamp;
            }
        } else revert("Invalid punishment");
        _citizens[sentenced].nbOfCurrentAccountTokens = _currentBalance;
    }

    /// @dev function for revocation of citizenship
    function denaturalize(address sentenced) public onlySovereign {
        /// @dev addresses of sovereign and not a citizen cannot be denaturalized
        require(sentenced != _sovereign, "sovereign cannot loose citizenship");
        require(_citizens[sentenced].isAlive == true, "impossible punishment: not an alive citizen");
        _citizens[sentenced].isAlive = false;
        _citizens[sentenced].employer = address(0);
        _citizens[sentenced].isWorking = false;
        _citizens[sentenced].isSick = false;
        _citizens[sentenced].nbVotes = 0;
        _citizens[sentenced].termAdmin = 0;
        _citizens[sentenced].retirementDate = 0;
        _citizens[sentenced].termBanned = 0;
        _citizens[sentenced].nbOfCurrentAccountTokens = 0;
        _citizens[sentenced].nbOfHealthInsuranceTokens = 0;
        _citizens[sentenced].nbOfUnemploymentTokens = 0;
        _citizens[sentenced].nbOfRetirementTokens = 0;
        _token.transferFrom(sentenced, _sovereign, _token.balanceOf(sentenced));
    }

    /// @dev function for sovereign to pardon citizens before their _banishment term
    function pardon(address pardoned) public onlySovereign {
        _citizens[pardoned].termBanned = block.timestamp;
    }

    /// @dev function to change a citizen's health status
    function changeHealthStatus(address concerned, HealthStatus option) public onlyAdmin {
        if (option == HealthStatus.Died) {
            _citizens[concerned].isAlive = false;
            //if the citizen is an admin
            if (_citizens[concerned].termAdmin > block.timestamp) {
                _citizens[concerned].termAdmin = block.timestamp;
            }
            _citizens[concerned].nbOfCurrentAccountTokens = 0;
            _citizens[concerned].nbOfHealthInsuranceTokens = 0;
            _citizens[concerned].nbOfUnemploymentTokens = 0;
            _citizens[concerned].nbOfRetirementTokens = 0;
            _token.transferFrom(concerned, _sovereign, _token.balanceOf(concerned));
        } else if (option == HealthStatus.Healthy) {
            _citizens[concerned].isSick = false;
        } else if (option == HealthStatus.Sick) {
            _citizens[concerned].isSick = true;
            _citizens[concerned].nbOfCurrentAccountTokens += _citizens[concerned].nbOfHealthInsuranceTokens;
            _citizens[concerned].nbOfHealthInsuranceTokens = 0;
        } else revert("Invalid health status choice");
    }

    /// @dev function to change a citizen's employment status
    function changeEmploymentStatus(address concerned) public onlyAdmin {
        if (_citizens[concerned].isWorking == true) {
            _citizens[concerned].isWorking = false;
            _citizens[concerned].nbOfCurrentAccountTokens += _citizens[concerned].nbOfUnemploymentTokens;
            _citizens[concerned].nbOfUnemploymentTokens = 0;
        } else {
            _citizens[concerned].isWorking = true;
        }
    }

    // For citizens : actions

    /** @dev function to get citizenship, future citizen needs to approve before
     * the government address for token cap before getting the award (so it's
     *  possible afterwards for the government address to transfer his tokens)
     */
    function becomeCitizen(
        uint8 age,
        bool isWorking,
        bool isSick
    ) public {
        require(_citizens[msg.sender].retirementDate == 0, "citizens can not ask again for citizenship");
        require(
            _token.allowance(msg.sender, address(this)) == _token.cap(),
            "future citizen needs to approve government address"
        );
        uint256 retirementDate = RETIREMENT_AGE >= age
            ? block.timestamp + (RETIREMENT_AGE - age) * 52 weeks
            : block.timestamp;
        _token.transferFrom(_sovereign, msg.sender, AWARD_CITIZENSHIP);
        _citizens[msg.sender] = Citizen(
            true,
            address(0),
            isWorking,
            isSick,
            0,
            0,
            retirementDate,
            0,
            AWARD_CITIZENSHIP,
            0,
            0,
            0
        );
    }

    /// @dev function to ask for retirement
    function getRetired() public onlyAliveCitizens onlyAllowedCitizens {
        require(_citizens[msg.sender].retirementDate <= block.timestamp, "retirement possible only at 67");
        _citizens[msg.sender].isWorking = false;
        _citizens[msg.sender].nbOfCurrentAccountTokens += _citizens[msg.sender].nbOfRetirementTokens;
        _citizens[msg.sender].nbOfRetirementTokens = 0;
    }
}
