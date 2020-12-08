# Solidity Patterns chosen

(cf.https://fravoll.github.io/solidity-patterns/)

- ## Checks Effects Interactions:

  **Objective**: Reduce the attack surface for malicious contracts trying to hijack control flow after an external call.  
  **Example Use Case**: for functions `buyTokens` and `paySalary` we first check using `require`, then update the storage and in the end we interact with external environment by calling ERC777' `operatorSend` or `transfer` functions
