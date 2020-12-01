// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Token.sol";

/// @author Mihai Doldur
/// @title A government contract for a token economy

//contract State deployed at

/* TODO: 
- import and use SafeMath import Ownable / Access Control from OZ to
replace onlyOwner? 
- remove Elections properties from Citizen struct
- Test : test every function, require, modifier 
- emit Events for state changes (ex. UpdatedCitizen or specific event for each change
ChangedHealth, ChosenAdmin etc.) 
- add NatSpec comments

*/
contract State is Ownable {
    using SafeMath for uint256;

    // Variables of state

    //address of the sovereign
    address payable private _sovereign;

    //national token
    Token private _token;

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

    /// @dev mapping from an address to a Citizen
    mapping(address => Citizen) private _citizens;

    /// @dev mapping from an address to boolean for admins
    mapping(address => bool) private _admins;

    /// @dev mapping to register a company: companies[address] = true
    mapping(address => bool) private _companies;

    //constants
    uint256 constant RETIREMENT_AGE = 67;
    uint256 constant DENOMINATION = 10**18;
    uint256 constant AWARD_CITIZENSHIP = 100 * DENOMINATION;
    uint256 constant STAKE_ADMIN = 100 * DENOMINATION;

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
    constructor(address owner_, uint256 priceFull) public {
        transferOwnership(owner_);
        _price = priceFull;
        //  cast address to address payable
        //_ownerAddress = payable(owner_);
        //_ownerAddress = address(uint160(owner_));
        _sovereign = payable(owner()); // sovereign;
    }

    //Modifiers

    /*     // A modifier for checking if the msg.sender is the sovereign (e.g. president, king)
    modifier onlySovereign() {
        require(msg.sender == _sovereign, "ERC20: Only sovereign can perform this action");
        _;
    } */

    /// @dev modifier to check if admin
    modifier onlyAdmin() {
        require(_admins[msg.sender] == true, "only admin can perform this action");
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

    /// @dev modifier to check if company registered
    modifier onlyCompanies() {
        require(_companies[msg.sender] == true, "Only a company can perform this action");
        _;
    }

    function setToken() external {
        require(address(_token) == address(0), "App: token address must be address 0");
        _token = Token(msg.sender);
    }

    /// @dev function for the sovereign to name admins
    function setAdmin(address adminAddress) public onlyOwner {
        require(
            _citizens[adminAddress].nbOfCurrentAccountTokens >= STAKE_ADMIN,
            "candidate does not have enough CTZ to become admin"
        );
        // require(citizen(adminAddress).termBanned < block.timestamp, "candidate is banned");
        _admins[adminAddress] = true;
    }

    //Getter functions yo view private variables

    // Returns the properties of a citizen
    function getCitizen(address citizenAddress) public view returns (Citizen memory) {
        return _citizens[citizenAddress];
    }

    // Returns the properties of a citizen
    function checkAdmin(address adminAddress) public view returns (bool) {
        return _admins[adminAddress];
    }

    function updateCitizenTermAdmin(address citizenAddress, uint256 term) public onlyAdmin {
        _citizens[citizenAddress].termAdmin = term;
    }

    function updateCitizenNbVotes(address citizenAddress, uint256 nbVotes) public onlyAdmin {
        _citizens[citizenAddress].nbVotes = nbVotes;
    }

    // Get address of deployed token contract
    function getToken() public view returns (address) {
        return address(_token);
    }

    // Get address of sovereign (STATE)
    function sovereign() public view returns (address payable) {
        return _sovereign;
    }

    // Gets price of 1 full CTZ (10^18 units of token) in wei
    function price() public view returns (uint256) {
        return _price;
    }

    /// @dev function for revocation of citizenship
    function _cancelCitizen(address addr) private {
        /// @dev addresses of sovereign and not a citizen cannot be denaturalized
        //if the citizen is an admin
        if (_admins[addr] == true) {
            _admins[addr] = false;
        }
        _citizens[addr].isAlive = false;
        _citizens[addr].employer = address(0);
        _citizens[addr].isWorking = false;
        _citizens[addr].isSick = false;
        _citizens[addr].nbVotes = 0;
        _citizens[addr].termAdmin = 0;
        _citizens[addr].retirementDate = 0;
        _citizens[addr].termBanned = 0;
        _citizens[addr].nbOfCurrentAccountTokens = 0;
        _citizens[addr].nbOfHealthInsuranceTokens = 0;
        _citizens[addr].nbOfUnemploymentTokens = 0;
        _citizens[addr].nbOfRetirementTokens = 0;
        _token.operatorSend(addr, _sovereign, _token.balanceOf(addr), "", "");
    }

    /// @dev function for revocation of citizenship
    function denaturalize(address sentenced) public onlyAdmin {
        /// @dev addresses of sovereign and not a citizen cannot be denaturalized
        require(sentenced != _sovereign, "sovereign cannot loose citizenship");
        require(_citizens[sentenced].isAlive == true, "impossible punishment: not an alive citizen");
        _cancelCitizen(sentenced);
    }

    /// @dev function to change a citizen's health status
    function changeHealthStatus(address concerned, HealthStatus option) public onlyAdmin {
        if (option == HealthStatus.Died) {
            _cancelCitizen(concerned);
        } else if (option == HealthStatus.Healthy) {
            _citizens[concerned].isSick = false;
        } else if (option == HealthStatus.Sick) {
            _citizens[concerned].isSick = true;
            _citizens[concerned].nbOfCurrentAccountTokens = _citizens[concerned].nbOfCurrentAccountTokens.add(
                _citizens[concerned].nbOfHealthInsuranceTokens
            );
            _citizens[concerned].nbOfHealthInsuranceTokens = 0;
        } else revert("Invalid health status choice");
    }

    /// @dev function to change a citizen's employment status
    function changeEmploymentStatus(address concerned) public onlyAdmin {
        if (_citizens[concerned].isWorking == true) {
            _citizens[concerned].isWorking = false;
            _citizens[concerned].nbOfCurrentAccountTokens = _citizens[concerned].nbOfCurrentAccountTokens.add(
                _citizens[concerned].nbOfUnemploymentTokens
            );
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
        /*         require(
            _token.allowance(msg.sender, address(this)) == _token.cap(),
            "future citizen needs to approve government address"
        ); */
        uint256 retirementDate = RETIREMENT_AGE >= age
            ? block.timestamp.add((RETIREMENT_AGE.sub(age)).mul(52 weeks))
            : block.timestamp;
        _token.operatorSend(_sovereign, msg.sender, AWARD_CITIZENSHIP, "", "");
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
        _citizens[msg.sender].nbOfCurrentAccountTokens = _citizens[msg.sender].nbOfCurrentAccountTokens.add(
            _citizens[msg.sender].nbOfRetirementTokens
        );
        _citizens[msg.sender].nbOfRetirementTokens = 0;
    }

    // companies

    /// @dev function to register a company
    function registerCompany(address companyAddress) public onlyAdmin {
        require(_companies[companyAddress] == false, "company is already registered");
        _companies[companyAddress] = true;
    }

    // Checks if a company is registered
    function checkCompany(address companyAddress) public view returns (bool) {
        return _companies[companyAddress];
    }

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
        _token.operatorSend(_sovereign, msg.sender, nbTokens, "", "");
        _sovereign.transfer(_realPrice);
        if (_remaining > 0) {
            msg.sender.transfer(_remaining);
        }
        return true;
    }

    /// @dev function to recruit a citizen
    function recruit(address employee) public onlyCompanies {
        require(_citizens[employee].employer != msg.sender, "employee already working for this company");
        _citizens[employee].employer = msg.sender;
    }

    /// @dev function for a company to pay salaries
    function paySalary(address employee, uint256 amount) public onlyCompanies {
        require(_citizens[employee].employer == msg.sender, "not an employee of this company");
        require(_token.balanceOf(msg.sender) >= amount, "company balance is less than the amount");
        _citizens[employee].nbOfHealthInsuranceTokens = amount / 10;
        _citizens[employee].nbOfUnemploymentTokens = amount / 10;
        _citizens[employee].nbOfRetirementTokens = amount / 10;
        _citizens[employee].nbOfCurrentAccountTokens =
            _token.balanceOf(employee) -
            _citizens[employee].nbOfHealthInsuranceTokens -
            _citizens[employee].nbOfUnemploymentTokens -
            _citizens[employee].nbOfRetirementTokens;
        _token.send(employee, amount, "");
    }
}
