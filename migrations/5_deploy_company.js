// CitizenERC20 is an artifact of the CitizenERC20 contract
const CitizenERC20 = artifacts.require('CitizenERC20');
// Government is an artifact of the Government contract
const Government = artifacts.require('Government');
// Government is an artifact of the Government contract
const Company = artifacts.require('Company');

module.exports = (deployer) => {
  deployer.deploy(
    Company,
    CitizenERC20.address, // use CitizenERC20 address from artifact
    Government.address, // use Government address from artifact
  );
};
