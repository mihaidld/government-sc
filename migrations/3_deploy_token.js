const Token = artifacts.require('Token');
const Government = artifacts.require('Government');
const BN = web3.utils.BN;

module.exports = (deployer) => {
  deployer.deploy(
    Token,
    '0x0f16385df3b467E4889b50907C365d3146016Cce',
    new BN('1000000000000000000000000'),
    Government.address,
    [Government.address],
  );
};
