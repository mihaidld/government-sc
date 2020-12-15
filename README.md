# Ethereum Smart Contracts in Solidity for DApp CITIZEN project

## Presentation

DApp CITIZEN is a project to create a token economy and manage a fictional country and its citizens by deploying smart contracts on Ethereum blockchain written in Solidity :

_Token.sol_ handles the token  
_Government.sol_ handles State Affairs.

- contracts inherit from Open Zeppelin contracts `ERC777` and `Ownable` already tested contracts and use `SafeMath` library
- testing done using `Mocha` test framework, `Chai` assertion library and Open Zeppelin's `Test Environment` and `Test Helpers`
- deployment via `Truffle` on Rinkeby Testnet
- comments using `NatSpec` format which generate documentation via `solidity-docgen`

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
1 ETH == 100 CTZ.  
100 `CITIZEN` are automatically awarded to any individual who wishes to become a citizen.

### **Sovereign**

An entity called `sovereign` is the owner of the state, has the right to register and unregister companies and hospitals or to denaturalize citizens.  
It is minted, during token contract deployment, 100% of the total supply (1 million `CTZ`) and retains the right to `burn` or `mint` tokens `CTZ` in the future in order to regulate the economy.

### **Companies**

A company is identified by its Ethereum address and, in order to function, it must be first registered by the sovereign.  
It can then buy `CTZ` from the sovereign.  
A company can recruit employees among the registered citizens, pay them salaries in `CTZ` tokens and dismiss them.

### **Hospitals**

A hospital is identified by its Ethereum address and, in order to function, it must be first registered by the sovereign.  
A hospital can change the health status of a registered citizen between healthy and sick, or declare the death of a citizen.

### **The citizens**

The citizens are identified by their Ethereum address and can have different `properties`:

- alive / dead
- healthy / sick
- working / unemployed
- an employer
- a date when it's possible to ask for retirement etc.

A citizen has also a balance of `CTZ` spread between a `current account`, an `unemployment insurance`, a `health insurance` and a `retirement insurance`. Only the current account is at the citizen's disposal.

**Life events :**

- A `new citizen` is awarded 100 CTZ which go into the current account.
- The `salary` received from an employer is spread as follows: 10% for unemployment insurance, 10% for health insurance, 10% for retirement insurance and the remaining 70% into the current account.
- On employer's `dismissal` all unemployment insurance tokens are transfered into the current account.
- On being declared `sick` by a hospital all health insurance tokens are transfered into the current account.
- At `retirement` (if above retirement age) all unemployment insurance and retirement insurance tokens are transferred into the current account.
- On being declared `dead` by a hospital all tokens of the deceased are given back to the sovereign.
