// CitizenERC20 is an artifact of the CitizenERC20 contract
const CitizenERC20 = artifacts.require('CitizenERC20');
// Government is an artifact of the Government contract
const Government = artifacts.require('Government');
const BN = web3.utils.BN;

module.exports = async (deployer) => {
  await deployer.deploy(
    Government,
    CitizenERC20.address, // use CitizenERC20 address from artifact
    new BN('10000000000000000'),
  );
};
