// CitizenERC20 is an artifact of the CitizenERC20 contract
const CitizenERC20 = artifacts.require('CitizenERC20');
const BN = web3.utils.BN;

module.exports = async (deployer) => {
  await deployer.deploy(
    CitizenERC20,
    'CITIZEN',
    'CTZ',
    18,
    new BN('1000000000000000000000000'),
    new BN('1000000000000000000000000'),
    '0x0f16385df3b467E4889b50907C365d3146016Cce',
  );
};
