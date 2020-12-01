// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./State.sol";

//contract Token deployed at

/*
TODO: add capped ou pausable?
 */

// ERC777
contract Token is ERC777, Ownable {
    // address payable private _ownerAddress;

    //state
    State private _state;

    constructor(
        address owner_,
        uint256 initialSupply,
        address appAddress,
        address[] memory defaultOperators
    ) public ERC777("CITIZEN", "CTZ", defaultOperators) {
        _state = State(appAddress);
        transferOwnership(owner_);
        _mint(owner(), initialSupply, "", "");
        _state.setToken();
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount, "", "");
    }
}
