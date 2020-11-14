// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./CitizenERC20.sol";

//contract CitizenERC20 deployed at 0x52Cd8781bb6b37e748aE5Ff52a9385D95409bcE3
//contract Government deployed at 0x93188988493Baf351F891a95DFAE1e4D7BA519Ef

/* contract Government {
    // Variables of state

    //address of the sovereign
    address payable private _sovereign;

    //national token
    CitizenERC20 private _token;

    // price of 1 full CTZ (10^18 units of token) in wei;
    uint256 private _price;

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

    /// @dev struct Proposal to be voted by admins
    struct Proposal {
        string question; // proposal question
        string description; // proposal description
        uint256 counterForVotes; // counter of votes `Yes`
        uint256 counterAgainstVotes; // counter of votes `No`
        uint256 counterBlankVotes; // counter of votes `Blank`
    }

    /// @dev mapping from an address to a Citizen
    mapping(address => Citizen) private _citizens;

    /// @dev mapping to register a company: companies[address] = true
    mapping(address => bool) private _companies;

    /// @dev mapping to check last date of vote (so an address can not vote twice during a mandate)
    mapping(address => uint256) private _dateVote;

    /// @dev mapping from an id of proposal to a Proposal
    mapping(uint256 => Proposal) private _proposals;

    /// @dev counter for proposal id incremented by each proposal creation
    uint8 private _counterIdProposal;

    /// @dev mapping to check that an address can not vote twice for same proposal id
    mapping(address => mapping(uint8 => bool)) private _didVoteForProposal;

    //Other variables
    uint8 private _retirementAge = 67;
    uint8 private _majorityAge = 18;
    uint256 private _currentMandateTerm;
    uint256 private _mandateDuration = 8 weeks;
    uint256 private _electionsDuration = 1 weeks;
    uint8 private _nbMinimumVotesToGetElected = 5;
    uint256 private _denomination = 10**18;
    uint256 private _smallPunishment = 5 * _denomination;
    uint256 private _moderatePunishment = 50 * _denomination;
    uint256 private _seriousPunishment = 100 * _denomination;
    uint256 private _awardCitizenship = 100 * _denomination;
    uint256 private _stakeAdmin = 100 * _denomination;
    uint256 private _banishment = 10 * 52 weeks;

    /// @notice options to be voted by admins: 0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason, other -> Invalid choice
    string public howToPunish = "0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason";
    /// @dev punishment options using enum type: 0 -> Punishment.Small, 1 -> Punishment.Moderate, 2 -> Punishment.Serious, 3 -> Punishment.Treason
    enum Punishment {Small, Moderate, Serious, Treason}

    /// @notice instructions to vote by admins: 0 -> Blank, 1 -> Yes, 2 -> No, other -> Invalid vote
    string public howToVote = "0 -> Blank, 1 -> Yes, 2 -> No";
    /// @dev vote options using enum type: 0 -> Option.Blank, 1 -> Option.Yes, 2 -> Option.No
    enum Option {Blank, Yes, No}

    /// @notice instructions to change health status by admins: 0 -> Died, 1 -> Healthy, 2 -> Sick, other -> Invalid choice
    string public healthStatusOptions = "0 -> Died, 1 -> Healthy, 2 -> Sick";
    /// @dev health status options using enum type: 0 -> HealthStatus.Died, 1 -> HealthStatus.Healthy, 2 -> HealthStatus.Sick
    enum HealthStatus {Died, Healthy, Sick}

    /// @dev priceFull for 1 full CTZ (10^18 tokens) in wei : 10**16 or 0.01 ether or 10000000000000000
    constructor(address _tokenAddress, uint256 _priceFull) public {
        _token = CitizenERC20(_tokenAddress);
        _price = _priceFull;
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
            _citizens[msg.sender].retirementDate < (block.timestamp + (_retirementAge - 18) * 52 weeks),
            "only adults can perform this action"
        );
        _;
    }

    /// @dev modifier to check if company registered
    modifier onlyCompanies() {
        require(_companies[msg.sender] == true, "Only a company can perform this action");
        _;
    }

    //Getter functions yo view private variables

    // Returns the properties of a citizen
    function citizen(address _citizenAddress) public view returns (Citizen memory) {
        return _citizens[_citizenAddress];
    }

    // Gets properties of a proposal
    function proposal(uint8 _id) public view returns (Proposal memory) {
        return _proposals[_id];
    }

    // Checks if a company is registered
    function company(address _companyAddress) public view returns (bool) {
        return _companies[_companyAddress];
    }

    // Get address of deployed token contract TODO
    function tokenAddress() public view returns (CitizenERC20) {
        return _token;
    }

    // Gets price of 1 full CTZ (10^18 units of token) in wei
    function price() public view returns (uint256) {
        return _price;
    }

    // Gets date of the last election vote of a citizen
    function dateVote(address _electorAddress) public view returns (uint256) {
        return _dateVote[_electorAddress];
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
    function elect(address _candidateAddress)
        public
        onlyAdults
        onlyAliveCitizens
        onlySolventCitizens
        onlyAllowedCitizens
    {
        require(
            _citizens[_candidateAddress].retirementDate < block.timestamp + (_retirementAge - _majorityAge) * 52 weeks,
            "only adults can be elected"
        );
        require(block.timestamp >= _currentMandateTerm - 1 weeks, "too early to elect");
        require(block.timestamp <= _currentMandateTerm, "too late to elect");
        require(
            _citizens[_candidateAddress].nbOfCurrentAccountTokens >= _stakeAdmin,
            "candidate doesn't have enough CTZ to be elected"
        );
        require(_citizens[_candidateAddress].isAlive == true, "candidate is not a citizen");
        require(_citizens[_candidateAddress].termBanned < block.timestamp, "candidate is banned");
        require(
            _dateVote[msg.sender] < _currentMandateTerm - _mandateDuration,
            "citizen already voted for this election"
        );
        _citizens[_candidateAddress].nbVotes++;
        _dateVote[msg.sender] = block.timestamp;
    }

    /// @dev function for the sovereign to set new mandate term
    function updateMandate() public onlySovereign {
        _currentMandateTerm = block.timestamp + _mandateDuration;
    }

    /// @dev function for the sovereign to name admins following election results after setting a new mandate term
    function setAdmin(address _adminAddress) public onlySovereign {
        require(
            _citizens[_adminAddress].nbVotes >= _nbMinimumVotesToGetElected,
            "candidate has not received the minimum number of votes"
        );
        require(
            _citizens[_adminAddress].nbOfCurrentAccountTokens >= _stakeAdmin,
            "candidate doesn't have enough CTZ to be elected"
        );
        require(_citizens[_adminAddress].isAlive == true, "candidate is not a citizen");
        require(_citizens[_adminAddress].termBanned < block.timestamp, "candidate is banned");
        _citizens[_adminAddress].termAdmin = _currentMandateTerm;
        _citizens[_adminAddress].nbVotes = 0; //reset to 0 number of votes
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

    /// @dev function to give sentences
    function punish(address _sentenced, Punishment _option) public onlyAdmin {
        /// @dev addresses of sovereign and not a citizen cannot be punished
        require(_sentenced != _sovereign, "sovereign cannot be punished");
        require(_citizens[_sentenced].isAlive == true, "impossible punishment: not an alive citizen");
        uint256 _currentBalance = _citizens[_sentenced].nbOfCurrentAccountTokens;
        if (_option == Punishment.Small) {
            _currentBalance = _currentBalance > _smallPunishment ? _currentBalance - _smallPunishment : 0;
        } else if (_option == Punishment.Moderate) {
            _currentBalance = _currentBalance > _moderatePunishment ? _currentBalance - _moderatePunishment : 0;
        } else if (_option == Punishment.Serious) {
            _currentBalance = _currentBalance > _seriousPunishment ? _currentBalance - _seriousPunishment : 0;
        } else if (_option == Punishment.Treason) {
            _currentBalance = 0;
            _citizens[_sentenced].nbOfHealthInsuranceTokens = 0;
            _citizens[_sentenced].nbOfUnemploymentTokens = 0;
            _citizens[_sentenced].nbOfRetirementTokens = 0;
            _citizens[_sentenced].termBanned = block.timestamp + _banishment;
            _token.transferFrom(_sentenced, _sovereign, _token.balanceOf(_sentenced));
            //if the citizen is an admin
            if (_citizens[_sentenced].termAdmin > block.timestamp) {
                _citizens[_sentenced].termAdmin = block.timestamp;
            }
        } else revert("Invalid punishment");
        _citizens[_sentenced].nbOfCurrentAccountTokens = _currentBalance;
    }

    /// @dev function for revocation of citizenship
    function denaturalize(address _sentenced) public onlySovereign {
        /// @dev addresses of sovereign and not a citizen cannot be denaturalized
        require(_sentenced != _sovereign, "sovereign cannot loose citizenship");
        require(_citizens[_sentenced].isAlive == true, "impossible punishment: not an alive citizen");
        _citizens[_sentenced].isAlive = false;
        _citizens[_sentenced].employer = address(0);
        _citizens[_sentenced].isWorking = false;
        _citizens[_sentenced].isSick = false;
        _citizens[_sentenced].nbVotes = 0;
        _citizens[_sentenced].termAdmin = 0;
        _citizens[_sentenced].retirementDate = 0;
        _citizens[_sentenced].termBanned = 0;
        _citizens[_sentenced].nbOfCurrentAccountTokens = 0;
        _citizens[_sentenced].nbOfHealthInsuranceTokens = 0;
        _citizens[_sentenced].nbOfUnemploymentTokens = 0;
        _citizens[_sentenced].nbOfRetirementTokens = 0;
        _token.transferFrom(_sentenced, _sovereign, _token.balanceOf(_sentenced));
    }

    /// @dev function for sovereign to pardon citizens before their _banishment term
    function pardon(address _beneficiary) public onlySovereign {
        _citizens[_beneficiary].termBanned = block.timestamp;
    }

    /// @dev function to change a citizen's health status
    function changeHealthStatus(address _concerned, HealthStatus _option) public onlyAdmin {
        if (_option == HealthStatus.Died) {
            _citizens[_concerned].isAlive = false;
            //if the citizen is an admin
            if (_citizens[_concerned].termAdmin > block.timestamp) {
                _citizens[_concerned].termAdmin = block.timestamp;
            }
            _citizens[_concerned].nbOfCurrentAccountTokens = 0;
            _citizens[_concerned].nbOfHealthInsuranceTokens = 0;
            _citizens[_concerned].nbOfUnemploymentTokens = 0;
            _citizens[_concerned].nbOfRetirementTokens = 0;
            _token.transferFrom(_concerned, _sovereign, _token.balanceOf(_concerned));
        } else if (_option == HealthStatus.Healthy) {
            _citizens[_concerned].isSick = false;
        } else if (_option == HealthStatus.Sick) {
            _citizens[_concerned].isSick = true;
            _citizens[_concerned].nbOfCurrentAccountTokens += _citizens[_concerned].nbOfHealthInsuranceTokens;
            _citizens[_concerned].nbOfHealthInsuranceTokens = 0;
        } else revert("Invalid health status choice");
    }

    /// @dev function to change a citizen's employment status
    function changeEmploymentStatus(address _concerned) public onlyAdmin {
        if (_citizens[_concerned].isWorking == true) {
            _citizens[_concerned].isWorking = false;
            _citizens[_concerned].nbOfCurrentAccountTokens += _citizens[_concerned].nbOfUnemploymentTokens;
            _citizens[_concerned].nbOfUnemploymentTokens = 0;
        } else {
            _citizens[_concerned].isWorking = true;
        }
    }

    /// @dev function to register a company
    function registerCompany(address _companyAddress) public onlyAdmin {
        require(_companies[_companyAddress] == false, "company is already registered");
        _companies[_companyAddress] = true;
    }

    // For citizens : actions

    /// @dev function to get citizenship
    function becomeCitizen(
        uint8 _age,
        bool _isWorking,
        bool _isSick
    ) public {
        require(_citizens[msg.sender].retirementDate == 0, "citizens can not ask again for citizenship");
        uint256 retirementDate = _retirementAge >= _age
            ? block.timestamp + (_retirementAge - _age) * 52 weeks
            : block.timestamp;
        _token.transferFrom(_sovereign, msg.sender, _awardCitizenship);
        _token.approve(address(this), _token.cap());
        _citizens[msg.sender] = Citizen(
            true,
            address(0),
            _isWorking,
            _isSick,
            0,
            0,
            retirementDate,
            0,
            _awardCitizenship,
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

    // For companies : actions

    /// @dev function for a company to buy CTZ
    // nbTokens is the number of units of a full token (e.g. 1 CTZ = 10^18 nbTokens)
    function buyTokens(uint256 nbTokens) public payable onlyCompanies returns (bool) {
        require(msg.value > 0, "minimum 1 wei");
        //check if minimum 100 units of token bought since 1 wei = 100 units
        require(nbTokens >= (10**uint256(_token.decimals()) / _price), "minimum 100 tokens");
        //check if enough ether for nbTokens
        require(
            (nbTokens * _price) / 10**uint256(_token.decimals()) <= msg.value,
            "not enough Ether to purchase this number of tokens"
        );
        uint256 _realPrice = (nbTokens * _price) / 10**uint256(_token.decimals());
        uint256 _remaining = msg.value - _realPrice;
        _token.transferFrom(_sovereign, msg.sender, nbTokens);
        _sovereign.transfer(_realPrice);
        if (_remaining > 0) {
            msg.sender.transfer(_remaining);
        }
        return true;
    }

    /// @dev function to recruit a citizen
    function recruit(address _employee) public onlyCompanies {
        require(_citizens[_employee].employer != msg.sender, "employee already working for this company");
        _citizens[_employee].employer = msg.sender;
    }

    /// @dev function for a company to pay salaries
    function paySalary(address payable _employee, uint256 _amount) public onlyCompanies {
        require(_citizens[_employee].employer == msg.sender, "not an employee of this company");
        require(_token.balanceOf(msg.sender) >= _amount, "company balance is less than the amount");
        _citizens[_employee].nbOfHealthInsuranceTokens = _amount / 10;
        _citizens[_employee].nbOfUnemploymentTokens = _amount / 10;
        _citizens[_employee].nbOfRetirementTokens = _amount / 10;
        _citizens[_employee].nbOfCurrentAccountTokens =
            _token.balanceOf(_employee) -
            _citizens[_employee].nbOfHealthInsuranceTokens -
            _citizens[_employee].nbOfUnemploymentTokens -
            _citizens[_employee].nbOfRetirementTokens;
        _token.transfer(_employee, _amount);
    }
}
 */
