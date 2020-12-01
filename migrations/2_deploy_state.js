const State = artifacts.require('State');
const BN = web3.utils.BN;

module.exports = (deployer) => {
  deployer.deploy(State, '0x0f16385df3b467E4889b50907C365d3146016Cce', new BN('1' + '0'.repeat(18)));
};
