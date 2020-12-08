## `Token`

Owner can mint and burn tokens


All function calls are currently implemented without side effects, the contract inherits OpenZeppelin contracts ERC777 and Ownable


### `constructor(address owner_, uint256 initialSupply, address appAddress, address[] defaultOperators)` (public)





### `mint(address account, uint256 amount)` (public)



mints tokens, can be called only by the owner



