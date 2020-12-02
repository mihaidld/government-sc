// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Token.sol";
import "./Government.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//contract Punishment deployed at

/* // TODO:



contract Judiciary is Ownable{
    //national token
    Token private _token;

    //state contract token
    State private _state;

    //constants

    uint256 constant DENOMINATION = 10**18;
    uint256 constant SMALL_PUNISHMENT = 5 * DENOMINATION;
    uint256 constant MODERATE_PUNISHMENT = 50 * DENOMINATION;
    uint256 constant SERIOUS_PUNISHMENT = 100 * DENOMINATION;
    uint256 constant BANISHMENT = 10 * 52 weeks;

    /// @notice options to be voted by admins: 0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason, other -> Invalid choice
    string public howToPunish = "0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason";
    /// @dev punishment options using enum type: 0 -> Punishment.Small, 1 -> Punishment.Moderate, 2 -> Punishment.Serious, 3 -> Punishment.Treason
    enum Punishment {Small, Moderate, Serious, Treason}

    constructor(address tokenAddress, address stateAddress ) public {
        _token = Token(tokenAddress);
        _state = State(stateAddress);
         transferOwnership(_state.sovereign());
    }

    /// @dev modifier to check if admin
    modifier onlyAdmin() {
        require(_state.citizen(msg.sender).termAdmin >= block.timestamp, "only admin can perform this action");
        _;
    }

    /// @dev function to give sentences
    function punish(address sentenced, Punishment option) public onlyAdmin {
        /// @dev addresses of sovereign and not a citizen cannot be punished
        require(sentenced != _state.sovereign(), "sovereign cannot be punished");
        require(_state.citizen(sentenced).isAlive == true, "impossible punishment: not an alive citizen");
        uint256 _currentBalance = _state.citizen(sentenced).nbOfCurrentAccountTokens;
        if (option == Punishment.Small) {
            _currentBalance = _currentBalance > SMALL_PUNISHMENT ? _currentBalance - SMALL_PUNISHMENT : 0;
        } else if (option == Punishment.Moderate) {
            _currentBalance = _currentBalance > MODERATE_PUNISHMENT ? _currentBalance - MODERATE_PUNISHMENT : 0;
        } else if (option == Punishment.Serious) {
            _currentBalance = _currentBalance > SERIOUS_PUNISHMENT ? _currentBalance - SERIOUS_PUNISHMENT : 0;
        } else if (option == Punishment.Treason) {
            _currentBalance = 0;
            _state.citizen(sentenced).nbOfHealthInsuranceTokens = 0;
            _state.citizen(sentenced).nbOfUnemploymentTokens = 0;
            _state.citizen(sentenced).nbOfRetirementTokens = 0;
            _state.citizen(sentenced).termBanned = block.timestamp + BANISHMENT;
            _token.operatorSend(sentenced, _state.sovereign(), _token.balanceOf(sentenced), "", "");
            //if the citizen is an admin
            if (_state.citizen(sentenced).termAdmin > block.timestamp) {
                _state.citizen(sentenced).termAdmin = block.timestamp;
            }
        } else revert("Invalid punishment");
        _state.citizen(sentenced).nbOfCurrentAccountTokens = _currentBalance;
    }

        /// @dev function for sovereign to pardon citizens before their _banishment term
    function pardon(address pardoned) public onlyOwner {
        _state.citizen(pardoned).termBanned = block.timestamp;
    }

}
*/
