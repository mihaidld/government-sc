## `Token`



All function calls are currently implemented without side effects,
the contract inherits OpenZeppelin contracts ERC777 and Ownable,
the owner can mint and burn tokens


### `constructor(address owner_, uint256 initialSupply, address appAddress, address[] defaultOperators)` (public)





### `mint(address account, uint256 amount)` (public)



mints tokens, can be called only by the owner



