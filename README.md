# Ethereum Smart Contracts in Solidity for DApp CITIZEN project

## Presentation

DApp CITIZEN is a project to create a token economy using 2 smart contracts for managing a country and its citizens :

_Token.sol_ handles the token  
_Government.sol_ handles State Affairs.

- contracts inherit from Open Zeppelin's `ERC777` and `Ownable` already tested contracts and use `SafeMath` library
- testing done using `Mocha`test framework, `Chai` assertion library and Open Zeppelin's `Test Environment` and `Test Helpers`
- deployment via `Truffle` on Rinkeby Testnet
- comments using `NatSpec` format who generate documentation via `solidity-docgen`

## Install

### Install dependencies:

```zsh
% yarn install
```

### Add environment variables:

Add _.env_ file with 2 variables `MNEMONIC` and `ENDPOINT_ID` from `Infura`

## Details of the project

### **token `CITIZEN`**

A token called `CITIZEN` (symbol `CTZ`, 18 decimals) serves as national currency and citizenship point inside this country.  
100 `CITIZEN` are automatically awarded to any individual who wishes to become a citizen.  
An entity called `sovereign` is the owner of the state, has the right to register and unregister companies and hospitals, denaturalize citizens and is minted, during token contract deployment, 100% of the supply of `CITIZEN` (1 million `CTZ`). The owner retains the right to `burn` or `mint` tokens `CTZ` in the future in order to regulate the economy.

### **Companies**

To function a company must be registered by the sovereign using its Ethereum address. It can then buy `CTZ` from the sovereign.  
A company can recruit employees from the registered citizens, pay them salaries in `CITIZEN` tokens and dismiss them.

### **Hospitals**

To function a hospital must be registered by the sovereign using its Ethereum address.  
A hospital can change the health status of a registered citizens between healthy and sick, and also can declare dead a citizen.

### **The citizens**

The citizens are identified by their Ethereum address and can have different `properties`:

- alive / dead
- healthy / sick
- working / unemployed
- an employer
- a date when it's possible to ask for retirement etc.

A citizen has also a balance of `CTZ` spread between his `current account`, `unemployment insurance`, `health insurance` and `retirement insurance`. Only the current account is at his disposal.

**Life events :**

- When becoming citizen, he is awarded 100 `CTZ` in his current account.
- When receiving a salary from his employer 10% of the salary go to his unemployment insurance, 10% to his health insurance, 10% to his retirement insurance and the remaining 70% to his current account.
- When being dismissed by the employer all unemployment insurance tokens are transfered to his current account.
- When being declared sick by a hospital all health insurance tokens are transfered to his current account.
- When requesting for retirement (if has reached retirement age) all unemployment insurance and retirement insurance tokens are transfered to his current account.
- When being declared dead by a hospital all his tokens are given back to the sovereign.
