// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./CitizenERC20.sol";
import "./Government.sol";

//contract Company deployed at 0x23F80Fe8445caBf3f46C8f2a92917d0C5DB72c00

/* TODO:

*/

contract Company {
    //national token
    CitizenERC20 private _token;

    //government contract token
    Government private _government;

    /// @dev mapping to register a company: companies[address] = true
    mapping(address => bool) private _companies;

    constructor(address tokenAddress, address governmentAddress) public {
        _token = CitizenERC20(tokenAddress);
        _government = Government(governmentAddress);
    }

    /// @dev modifier to check if admin
    modifier onlyAdmin() {
        require(_government.citizen(msg.sender).termAdmin >= block.timestamp, "only admin can perform this action");
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
        require(nbTokens >= (10**uint256(_token.decimals()) / _government.price()), "minimum 100 tokens");
        //check if enough ether for nbTokens
        require(
            (nbTokens * _government.price()) / 10**uint256(_token.decimals()) <= msg.value,
            "not enough Ether to purchase this number of tokens"
        );
        uint256 _realPrice = (nbTokens * _government.price()) / 10**uint256(_token.decimals());
        uint256 _remaining = msg.value - _realPrice;
        _token.transferFrom(_government.sovereign(), msg.sender, nbTokens);
        _government.sovereign().transfer(_realPrice);
        if (_remaining > 0) {
            msg.sender.transfer(_remaining);
        }
        return true;
    }

    /// @dev function to recruit a citizen
    function recruit(address employee) public view onlyCompanies {
        require(_government.citizen(employee).employer != msg.sender, "employee already working for this company");
        _government.citizen(employee).employer = msg.sender;
    }

    /// @dev function for a company to pay salaries
    function paySalary(address payable employee, uint256 amount) public onlyCompanies {
        require(_government.citizen(employee).employer == msg.sender, "not an employee of this company");
        require(_token.balanceOf(msg.sender) >= amount, "company balance is less than the amount");
        _government.citizen(employee).nbOfHealthInsuranceTokens = amount / 10;
        _government.citizen(employee).nbOfUnemploymentTokens = amount / 10;
        _government.citizen(employee).nbOfRetirementTokens = amount / 10;
        _government.citizen(employee).nbOfCurrentAccountTokens =
            _token.balanceOf(employee) -
            _government.citizen(employee).nbOfHealthInsuranceTokens -
            _government.citizen(employee).nbOfUnemploymentTokens -
            _government.citizen(employee).nbOfRetirementTokens;
        _token.transfer(employee, amount);
    }
}
