// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Token.sol";

/// @author Mihai Doldur
/// @title A contract for a country with a token economy
/// @notice You can register as a citizen, company or hospital of the contract.
/** @dev All function calls are currently implemented without side effects. The
 * contract inherits OpenZeppelin contract Ownable and uses SafeMath library
 */

/* TODO: 
- import and use Access Control from OZ to replace modifiers? 
- Test : test events token transfers (BecomeCitizen, BuyToken etc.) 
- check NatSpec comments
- module for company?
*/
contract Government is Ownable {
    using SafeMath for uint256;

    // Variables of storage

    /// @dev address payable of the sovereign
    address payable private _sovereign;

    /// @dev token used in economy
    Token private _token;

    /// @dev price of 1 full CTZ (10^18 units of token) in wei;
    uint256 private _price;

    /// @dev struct Citizen
    struct Citizen {
        bool isAlive; //true, after death false (the sovereign gets his balance)
        address employer; //company employing the citizen
        bool isWorking; //set by a company
        bool isSick; //set by a hospital
        uint256 retirementDate; //set when becoming citizen based on age
        uint256 currentTokens; //100 full tokens (100 * 10**18 at registration), can be increased by salaries
        uint256 healthTokens; //10% from each salary, acces to it when hospital declares citizen sick
        uint256 unemploymentTokens; //10% from each salary, acces to it when company declares citizen unemployed
        uint256 retirementTokens; //10% from each salary, acces to it at age 67
    }

    /// @dev mapping from an address to a Citizen
    mapping(address => Citizen) private _citizens;

    /// @dev mapping from an address to boolean to check if registered hospital
    mapping(address => bool) private _hospitals;

    /// @dev mapping from an address to boolean to check if registered company
    mapping(address => bool) private _companies;

    //constants
    uint256 constant RETIREMENT_AGE = 67;
    uint256 constant DENOMINATION = 10**18;
    uint256 constant AWARD_CITIZENSHIP = 100 * DENOMINATION;

    /// @notice instructions to change health status by hospitals: 0 -> Died, 1 -> Healthy, 2 -> Sick, other -> Invalid health status choice
    /// @dev health status options using enum type: 0 -> HealthStatus.Died, 1 -> HealthStatus.Healthy, 2 -> HealthStatus.Sick
    enum HealthStatus {Died, Healthy, Sick}

    /// @dev event emitted when a citizen is created
    event CreatedCitizen(
        address indexed citizenAddress,
        bool isAlive,
        address employer,
        bool isWorking,
        bool isSick,
        uint256 retirementDate,
        uint256 currentTokens,
        uint256 healthTokens,
        uint256 unemploymentTokens,
        uint256 retirementTokens
    );

    /// @dev event emitted when a citizen looses citizenship through denaturalization or death
    event LostCitizenship(address indexed citizenAddress);

    /// @dev event emitted when a hospital updates a citizen's health status between sick and healthy
    event UpdatedHealth(address indexed citizenAddress, bool isSick, uint256 currentTokens, uint256 healthTokens);

    /// @dev event emitted when a company updates a citizen's employment status between working and unemployed
    event UpdatedEmployment(
        address indexed citizenAddress,
        address employer,
        bool isWorking,
        uint256 currentTokens,
        uint256 unemploymentTokens
    );

    /// @dev event emitted when a citizen retires
    event Retired(
        address indexed citizenAddress,
        address employer,
        bool isWorking,
        uint256 currentTokens,
        uint256 unemploymentTokens,
        uint256 retirementTokens
    );

    /// @dev event emitted when the owner registers (sets to true) and unregisters (sets to false) a hospital
    event SetHospital(address indexed hospital, bool isHospital);

    /// @dev event emitted when the owner registers (sets to true) and unregisters (sets to false) a company
    event SetCompany(address indexed company, bool isCompany);

    /// @dev event emitted when a citizen is paid a salary
    event Paid(
        address indexed citizenAddress,
        uint256 indexed amount,
        address indexed employer,
        uint256 currentTokens,
        uint256 healthTokens,
        uint256 unemploymentTokens,
        uint256 retirementTokens
    );

    /// @dev transfers ownership to owner_, sets _price and casts owner address to address payable as _sovereign
    /// @param owner_ The address becoming owner of the contract
    /// @param priceFull Price of a 1 full CTZ (10^18 tokens) in wei : 10**16 or 0.01 ether or 10000000000000000
    constructor(address owner_, uint256 priceFull) public {
        transferOwnership(owner_);
        _price = priceFull;
        //_ownerAddress = payable(owner_);
        //_ownerAddress = address(uint160(owner_));
        _sovereign = payable(owner());
    }

    // Modifiers

    /// @dev modifier to check if msg.sender is a hospital
    modifier onlyHospitals() {
        require(_hospitals[msg.sender] == true, "Government: only a hospital can perform this action");
        _;
    }

    /// @dev modifier to check if msg.sender is an alive citizen
    modifier onlyAliveCitizens() {
        require(_citizens[msg.sender].isAlive == true, "Government: only alive citizens can perform this action");
        _;
    }

    /// @dev modifier to check if company registered
    modifier onlyCompanies() {
        require(_companies[msg.sender] == true, "Government: only a company can perform this action");
        _;
    }

    /// @dev private function for revocation of citizenship, sets citizen properties to 0 and transfers tokens to sovereign
    /// @param formerCitizen address of the citizen who looses citizenship by death or denaturalization
    function _cancelCitizen(address formerCitizen) private {
        _citizens[formerCitizen].isAlive = false;
        _citizens[formerCitizen].employer = address(0);
        _citizens[formerCitizen].isWorking = false;
        _citizens[formerCitizen].isSick = false;
        _citizens[formerCitizen].retirementDate = 0;
        _citizens[formerCitizen].currentTokens = 0;
        _citizens[formerCitizen].healthTokens = 0;
        _citizens[formerCitizen].unemploymentTokens = 0;
        _citizens[formerCitizen].retirementTokens = 0;
        _token.operatorSend(formerCitizen, _sovereign, _token.balanceOf(formerCitizen), "", "");
        LostCitizenship(formerCitizen);
    }

    // Getter functions to view private variables

    /// @dev returns the properties of a citizen
    /// @param citizenAddress The address of the citizen to be viewed
    /// @return the struct citizen
    function getCitizen(address citizenAddress) public view returns (Citizen memory) {
        return _citizens[citizenAddress];
    }

    /// @dev gets address of deployed Token contract
    /// @return the address of Token contract
    function getToken() public view returns (address) {
        return address(_token);
    }

    /// @dev gets address of sovereign (owner of Government and Token contracts)
    /// @return the address payable of the sovereign
    function sovereign() public view returns (address payable) {
        return _sovereign;
    }

    /// @dev gets price of 1 full CTZ (10^18 units of token) in wei
    /// @return price of 1 full CTZ
    function price() public view returns (uint256) {
        return _price;
    }

    /// @dev checks if a hospital is registered
    /// @param hospitalAddress Address of the hospital to be checked
    function checkHospital(address hospitalAddress) public view returns (bool) {
        return _hospitals[hospitalAddress];
    }

    /// @dev checks if a company is registered
    /// @param companyAddress Address of the company to be checked
    function checkCompany(address companyAddress) public view returns (bool) {
        return _companies[companyAddress];
    }

    // External and public setter functions

    /// @dev sets _token during Token contract construction with Token address and can be called only once
    function setToken() external {
        require(address(_token) == address(0), "Government: token address must be address 0");
        _token = Token(msg.sender);
    }

    /// @dev denaturalize a citizen to be called only by the sovereign, calls _cancelCitizen function
    /// @param sentenced Address of the citizen to be denaturalized
    function denaturalize(address sentenced) public onlyOwner {
        /// @dev addresses of sovereign and not an alive citizen cannot be denaturalized
        require(sentenced != _sovereign, "Government: sovereign cannot loose citizenship");
        require(_citizens[sentenced].isAlive == true, "Government: impossible punishment since not an alive citizen");
        _cancelCitizen(sentenced);
    }

    /** @dev change a citizen's health status to be called only by a hospital,
     *   in case of dying calls _cancelCitizen function, if becoming sick it
     *  transfers all tokens from health insurance into current account
     */
    /// @param concerned Address of the citizen with a health status changed
    /// @param option Option to change health status: 0 -> Died, 1 -> Healthy, 2 -> Sick, other -> Invalid health status choice
    function changeHealthStatus(address concerned, HealthStatus option) public onlyHospitals {
        require(_citizens[concerned].isAlive == true, "Government: can not change health since not an alive citizen");
        if (option == HealthStatus.Died) {
            _cancelCitizen(concerned);
        } else if (option == HealthStatus.Healthy) {
            _citizens[concerned].isSick = false;
            UpdatedHealth(concerned, false, _citizens[concerned].currentTokens, _citizens[concerned].healthTokens);
        } else if (option == HealthStatus.Sick) {
            _citizens[concerned].isSick = true;
            _citizens[concerned].currentTokens = _citizens[concerned].currentTokens.add(
                _citizens[concerned].healthTokens
            );
            _citizens[concerned].healthTokens = 0;
            UpdatedHealth(concerned, true, _citizens[concerned].currentTokens, _citizens[concerned].healthTokens);
        } else revert("Invalid health status choice");
    }

    /** @dev change a citizen's employment status to be called only by a
     * company, toggles between working and unemployed status, if becoming unemployed it
     * transfers all tokens from retirement insurance into current account
     */
    /// @param concerned Address of the citizen with an employment status changed
    function changeEmploymentStatus(address concerned) public onlyCompanies {
        require(
            _citizens[concerned].isAlive == true,
            "Government: can not change employment since not an alive citizen"
        );
        if (_citizens[concerned].isWorking == true) {
            /// @dev company A cannot change status of a citizen working for company B
            require(_citizens[concerned].employer == msg.sender, "Government: not working for this company");
            _citizens[concerned].isWorking = false;
            _citizens[concerned].employer = address(0);
            _citizens[concerned].currentTokens = _citizens[concerned].currentTokens.add(
                _citizens[concerned].unemploymentTokens
            );
            _citizens[concerned].unemploymentTokens = 0;
            UpdatedEmployment(
                concerned,
                address(0),
                false,
                _citizens[concerned].currentTokens,
                _citizens[concerned].unemploymentTokens
            );
        } else {
            _citizens[concerned].employer = msg.sender;
            _citizens[concerned].isWorking = true;
            UpdatedEmployment(
                concerned,
                msg.sender,
                true,
                _citizens[concerned].currentTokens,
                _citizens[concerned].unemploymentTokens
            );
        }
    }

    /// @dev creates a citizen (everybody can become a citizen by entering the age) and transfers award of 100 CTZ from sovereign account
    /// @param age Age of the new citizen, used to calculate retirement moment
    function becomeCitizen(uint256 age) public {
        /// @dev each new citizen has a retirementDate, so if the value of the property is different than 0, it means the msg.sender is already a citizen
        require(_citizens[msg.sender].retirementDate == 0, "Government: citizens can not ask again for citizenship");
        uint256 retirementDate = RETIREMENT_AGE >= age
            ? block.timestamp.add((RETIREMENT_AGE.sub(age)).mul(52 weeks))
            : block.timestamp;
        _citizens[msg.sender] = Citizen(true, address(0), false, false, retirementDate, AWARD_CITIZENSHIP, 0, 0, 0);
        _token.operatorSend(_sovereign, msg.sender, AWARD_CITIZENSHIP, "", "");
        CreatedCitizen(msg.sender, true, address(0), false, false, retirementDate, AWARD_CITIZENSHIP, 0, 0, 0);
    }

    /// @dev asks for retirement can be called only by an alive citizen, transfers tokens from retirement insurance into current account
    function getRetired() public onlyAliveCitizens {
        /// @dev can be called only when citizen's age is above official retirement age
        require(_citizens[msg.sender].retirementDate <= block.timestamp, "Government: retirement possible only at 67");
        _citizens[msg.sender].isWorking = false;
        _citizens[msg.sender].employer = address(0);
        uint256 _addedAmount = _citizens[msg.sender].unemploymentTokens.add(_citizens[msg.sender].retirementTokens);
        _citizens[msg.sender].currentTokens = _citizens[msg.sender].currentTokens.add(_addedAmount);
        _citizens[msg.sender].unemploymentTokens = 0;
        _citizens[msg.sender].retirementTokens = 0;
        Retired(msg.sender, address(0), false, _citizens[msg.sender].currentTokens, 0, 0);
    }

    /// @dev register a hospital, can be called only by the sovereign
    /// @param hospitalAddress Address of the hospital to be registered
    function registerHospital(address hospitalAddress) public onlyOwner {
        require(_hospitals[hospitalAddress] == false, "Government: hospital is already registered");
        _hospitals[hospitalAddress] = true;
        SetHospital(hospitalAddress, true);
    }

    /// @dev unregister a hospital, can be called only by the sovereign
    /// @param hospitalAddress Address of the hospital to be unregistered
    function unregisterHospital(address hospitalAddress) public onlyOwner {
        require(_hospitals[hospitalAddress] == true, "Government: hospital is already unregistered");
        _hospitals[hospitalAddress] = false;
        SetHospital(hospitalAddress, false);
    }

    /// @dev register a company, can be called only by the sovereign
    /// @param companyAddress Address of the company to be registered
    function registerCompany(address companyAddress) public onlyOwner {
        require(_companies[companyAddress] == false, "Government: company is already registered");
        _companies[companyAddress] = true;
        SetCompany(companyAddress, true);
    }

    /// @dev unregister a company, can be called only by the sovereign
    /// @param companyAddress Address of the company to be unregistered
    function unregisterCompany(address companyAddress) public onlyOwner {
        require(_companies[companyAddress] == true, "Government: company is already unregistered");
        _companies[companyAddress] = false;
        SetCompany(companyAddress, false);
    }

    /** @dev buy CTZ tokens, function payable can be called only by a company,
     * transfers tokens to company, transfers ether to sovereign,
     * if value is superior to cost, than the difference is sent to company
     */
    /// @param nbTokens The number of units of a full token (e.g. 1 CTZ = 10^18 nbTokens)
    /// @return a boolean to check if function was successfull
    function buyTokens(uint256 nbTokens) public payable onlyCompanies returns (bool) {
        /// @dev checks if msg.value is more than 0
        require(msg.value > 0, "Government: minimum 1 wei");
        /// @dev checks if minimum 100 units of token are bought since 1 wei = 100 units
        require(nbTokens >= (DENOMINATION / _price), "Government: minimum 100 tokens");
        /// @dev checks if enough ether is set as value to buy requested nbTokens
        require(
            (nbTokens * _price) / DENOMINATION <= msg.value,
            "Government: not enough Ether to purchase this number of tokens"
        );
        uint256 _realPrice = (nbTokens * _price) / DENOMINATION;
        uint256 _remaining = msg.value - _realPrice;
        _sovereign.transfer(_realPrice);
        _token.operatorSend(_sovereign, msg.sender, nbTokens, "", "");
        if (_remaining > 0) {
            msg.sender.transfer(_remaining);
        }
        return true;
    }

    /** @dev pays salaries, can be called only by a company, transfers tokens to
     * employee, and updates current account - 70% of the salary, health insurance,
     * unemployment insurance and retirement insurance - each 10% of the salary
     */
    /// @param employee Address of the employee receiving the salary
    /// @param amount Salary paid by company

    function paySalary(address employee, uint256 amount) public onlyCompanies {
        require(_citizens[employee].employer == msg.sender, "Government: not an employee of this company");
        require(_token.balanceOf(msg.sender) >= amount, "Government: company balance is less than the amount");
        uint256 _partSalary = amount.div(10);
        _citizens[employee].healthTokens = _citizens[employee].healthTokens.add(_partSalary);
        _citizens[employee].unemploymentTokens = _citizens[employee].unemploymentTokens.add(_partSalary);
        _citizens[employee].retirementTokens = _citizens[employee].retirementTokens.add(_partSalary);
        _citizens[employee].currentTokens = _citizens[employee].currentTokens.add(amount.sub(_partSalary.mul(3)));
        _token.operatorSend(msg.sender, employee, amount, "", "");
        Paid(
            employee,
            amount,
            msg.sender,
            _citizens[employee].currentTokens,
            _citizens[employee].healthTokens,
            _citizens[employee].unemploymentTokens,
            _citizens[employee].retirementTokens
        );
    }
}
