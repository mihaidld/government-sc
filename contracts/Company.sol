// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Token.sol";
import "./Government.sol";

//contract Company deployed at

/* TODO:



contract Company {
    //national token
    Token private _token;

    //state contract token
    State private _state;

    /// @dev mapping to register a company: companies[address] = true
    mapping(address => bool) private _companies;

    constructor(address tokenAddress, address stateAddress) public {
        _token = Token(tokenAddress);
        _state = State(stateAddress);
    }

    /// @dev modifier to check if admin
    modifier onlyAdmin() {
        require(_state.citizen(msg.sender).termAdmin >= block.timestamp, "only admin can perform this action");
        _;
    }

    /// @dev modifier to check if company registered
    modifier onlyCompanies() {
        require(_companies[msg.sender] == true, "Only a company can perform this action");
        _;
    }

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
        require(nbTokens >= (10**uint256(_token.decimals()) / _state.price()), "minimum 100 tokens");
        //check if enough ether for nbTokens
        require(
            (nbTokens * _state.price()) / 10**uint256(_token.decimals()) <= msg.value,
            "not enough Ether to purchase this number of tokens"
        );
        uint256 _realPrice = (nbTokens * _state.price()) / 10**uint256(_token.decimals());
        uint256 _remaining = msg.value - _realPrice;
        _token.operatorSend(_state.sovereign(), msg.sender, nbTokens, "", "");
        _state.sovereign().transfer(_realPrice);
        if (_remaining > 0) {
            msg.sender.transfer(_remaining);
        }
        return true;
    }

    /// @dev function to recruit a citizen
    function recruit(address employee) public view onlyCompanies {
        require(_state.citizen(employee).employer != msg.sender, "employee already working for this company");
        _state.citizen(employee).employer = msg.sender;
    }

    /// @dev function for a company to pay salaries
    function paySalary(address payable employee, uint256 amount) public onlyCompanies {
        require(_state.citizen(employee).employer == msg.sender, "not an employee of this company");
        require(_token.balanceOf(msg.sender) >= amount, "company balance is less than the amount");
        _state.citizen(employee).nbOfHealthInsuranceTokens = amount / 10;
        _state.citizen(employee).nbOfUnemploymentTokens = amount / 10;
        _state.citizen(employee).nbOfRetirementTokens = amount / 10;
        _state.citizen(employee).nbOfCurrentAccountTokens =
            _token.balanceOf(employee) -
            _state.citizen(employee).nbOfHealthInsuranceTokens -
            _state.citizen(employee).nbOfUnemploymentTokens -
            _state.citizen(employee).nbOfRetirementTokens;
        _token.send(employee, amount, "");
    }
}
*/
