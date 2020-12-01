/* eslint-disable no-unused-expressions */
const { contract, accounts } = require('@openzeppelin/test-environment');
const { BN, expectRevert, singletons } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const State = contract.fromArtifact('State');
const Token = contract.fromArtifact('Token');

describe('Token', function () {
  const NAME = 'CITIZEN';
  const SYMBOL = 'CTZ';
  const DECIMALS = 18;
  const INITIAL_SUPPLY = new BN('1000000' + '0'.repeat(DECIMALS));
  const PRICE_FULL = new BN('1' + '0'.repeat(16));
  const MINT_AMOUNT = new BN('1000' + '0'.repeat(DECIMALS));
  const [owner, dev, registryFunder] = accounts;

  context('contract construction', function () {
    /* Returns an instance of an ERC1820Registry deployed as per the specification.
This can be called multiple times to retrieve the same instance. */
    before(async function () {
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    });

    beforeEach(async function () {
      this.state = await State.new(owner, PRICE_FULL, { from: dev });
      this.token = await Token.new(owner, INITIAL_SUPPLY, this.state.address, [this.state.address], { from: dev });
    });

    it('has name', async function () {
      expect(await this.token.name()).to.equal(NAME);
    });

    it('has symbol', async function () {
      expect(await this.token.symbol()).to.equal(SYMBOL);
    });

    it('has one default operator', async function () {
      expect(await this.token.defaultOperators()).to.include(this.state.address);
      expect(await this.token.defaultOperators()).to.have.lengthOf(1);
    });

    it('transfers ownership from msg.sender to owner', async function () {
      expect(await this.token.owner()).to.equal(owner);
    });

    it('mints initial supply to owner', async function () {
      expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(INITIAL_SUPPLY);
    });

    it('sets token address on State contract', async function () {
      expect(await this.state.getToken(), { from: dev }).to.equal(this.token.address);
    });
  });

  context('mint function', function () {
    /* Returns an instance of an ERC1820Registry deployed as per the specification.
This can be called multiple times to retrieve the same instance. */
    before(async function () {
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    });

    beforeEach(async function () {
      this.state = await State.new(owner, PRICE_FULL, { from: dev });
      this.token = await Token.new(owner, INITIAL_SUPPLY, this.state.address, [this.state.address], { from: dev });
    });

    it('fails when other than owner tries to mint', async function () {
      await expectRevert(this.token.mint(dev, INITIAL_SUPPLY, { from: dev }), 'Ownable: caller is not the owner');
    });

    it('mints an amount to dev', async function () {
      expect(await this.token.balanceOf(dev), 'should be 0').to.be.bignumber.equal(new BN(0));
      await this.token.mint(dev, MINT_AMOUNT, { from: owner });
      expect(await this.token.balanceOf(dev), 'should be 1000').to.be.bignumber.equal(MINT_AMOUNT);
    });
  });
});
