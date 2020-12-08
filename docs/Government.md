## `Government`



All function calls are currently implemented without side effects. The
contract inherits OpenZeppelin contract Ownable and uses SafeMath library

### `onlyHospitals()`



modifier to check if msg.sender is a hospital

### `onlyAliveCitizens()`



modifier to check if msg.sender is an alive citizen

### `onlyCompanies()`



modifier to check if company registered


### `constructor(address owner_, uint256 priceFull)` (public)



transfers ownership to owner_, sets _price and casts owner address to address payable as _sovereign


### `getCitizen(address citizenAddress) → struct Government.Citizen` (public)



returns the properties of a citizen


### `getToken() → address` (public)



gets address of deployed Token contract


### `sovereign() → address payable` (public)



gets address of sovereign (owner of Government and Token contracts)


### `price() → uint256` (public)



gets price of 1 full CTZ (10^18 units of token) in wei


### `checkHospital(address hospitalAddress) → bool` (public)



checks if a hospital is registered


### `checkCompany(address companyAddress) → bool` (public)



checks if a company is registered


### `setToken()` (external)



sets _token during Token contract construction with Token address and can be called only once

### `denaturalize(address sentenced)` (public)



denaturalize a citizen to be called only by the sovereign, calls _cancelCitizen function


### `changeHealthStatus(address concerned, enum Government.HealthStatus option)` (public)





### `changeEmploymentStatus(address concerned)` (public)





### `becomeCitizen(uint256 age)` (public)



creates a citizen (everybody can become a citizen by entering the age) and transfers award of 100 CTZ from sovereign account


### `getRetired()` (public)



asks for retirement can be called only by an alive citizen, transfers tokens from retirement insurance into current account

### `registerHospital(address hospitalAddress)` (public)



register a hospital, can be called only by the sovereign


### `unregisterHospital(address hospitalAddress)` (public)



unregister a hospital, can be called only by the sovereign


### `registerCompany(address companyAddress)` (public)



register a company, can be called only by the sovereign


### `unregisterCompany(address companyAddress)` (public)



unregister a company, can be called only by the sovereign


### `buyTokens(uint256 nbTokens) → bool` (public)





### `paySalary(address employee, uint256 amount)` (public)






### `CreatedCitizen(address citizenAddress, bool isAlive, address employer, bool isWorking, bool isSick, uint256 retirementDate, uint256 currentTokens, uint256 healthTokens, uint256 unemploymentTokens, uint256 retirementTokens)`



event emitted when a citizen is created

### `LostCitizenship(address citizenAddress)`



event emitted when a citizen looses citizenship through denaturalization or death

### `UpdatedHealth(address citizenAddress, bool isSick, uint256 currentTokens, uint256 healthTokens)`



event emitted when a hospital updates a citizen's health status between sick and healthy

### `UpdatedEmployment(address citizenAddress, address employer, bool isWorking, uint256 currentTokens, uint256 unemploymentTokens)`



event emitted when a company updates a citizen's employment status between working and unemployed

### `Retired(address citizenAddress, address employer, bool isWorking, uint256 currentTokens, uint256 unemploymentTokens, uint256 retirementTokens)`



event emitted when a citizen retires

### `SetHospital(address hospital, bool isHospital)`



event emitted when the owner registers (sets to true) and unregisters (sets to false) a hospital

### `SetCompany(address company, bool isCompany)`



event emitted when the owner registers (sets to true) and unregisters (sets to false) a company

### `Paid(address citizenAddress, uint256 amount, address employer, uint256 currentTokens, uint256 healthTokens, uint256 unemploymentTokens, uint256 retirementTokens)`



event emitted when a citizen is paid a salary

