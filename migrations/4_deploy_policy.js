// Government is an artifact of the Government contract
const Government = artifacts.require('Government');
// Government is an artifact of the Government contract
const Policy = artifacts.require('Policy');

module.exports = async (deployer) => {
  await deployer.deploy(
    Policy,
    Government.address, // use Government address from artifact
  );
};
