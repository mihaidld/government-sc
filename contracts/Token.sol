// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Government.sol";

/// @author Mihai Doldur
/// @title A contract for an ERC777 token
/** @dev All function calls are currently implemented without side effects,
 * the contract inherits OpenZeppelin contracts ERC777 and Ownable,
 * the owner can mint and burn tokens
 */

contract Token is ERC777, Ownable {
    // Variables of storage
    /// @dev government contract which is the default operator
    Government private _government;

    /** @dev transfers ownership to _owner, sets address of Government token
     * becoming a default operator, mints to the owner of the contract an initial
     * supply of 1 million CTZ, calls setToken function of the Token contract,
     * sets name and symbol of the token
     */
    /// @param owner_ The address becoming owner of the contract
    /// @param initialSupply Amount of tokens minted to the owner
    /// @param appAddress Address of the Goverment contract operating the tokens
    /// @param defaultOperators Array with 1 element, the address of the Goverment contract
    constructor(
        address owner_,
        uint256 initialSupply,
        address appAddress,
        address[] memory defaultOperators
    ) public ERC777("CITIZEN", "CTZ", defaultOperators) {
        _government = Government(appAddress);
        transferOwnership(owner_);
        _mint(owner(), initialSupply, "", "");
        _government.setToken();
    }

    /// @dev mints tokens, can be called only by the owner
    /// @param account Address of the beneficiary
    /// @param amount Number of tokens being minted
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount, "", "");
    }
}
