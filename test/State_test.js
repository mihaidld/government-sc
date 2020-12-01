/* eslint-disable comma-dangle */
/* eslint-disable no-unused-expressions */
const { contract, accounts } = require('@openzeppelin/test-environment');
const { BN, singletons, constants, expectRevert, balance, send, ether, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const State = contract.fromArtifact('State');
const Token = contract.fromArtifact('Token');

// compare big numbers with a.eq(b)
const isSameCitizen = (_citizen, citizen) => {
  return (
    _citizen[0] === citizen[0] &&
    _citizen[1] === citizen[1] &&
    _citizen[2] === citizen[2] &&
    _citizen[3] === citizen[3] &&
    new BN(_citizen[4]).eq(citizen[4]) &&
    new BN(_citizen[5]).eq(citizen[5]) &&
    new BN(_citizen[6]).eq(citizen[6]) &&
    new BN(_citizen[7]).eq(citizen[7]) &&
    new BN(_citizen[8]).eq(citizen[8]) &&
    new BN(_citizen[9]).eq(citizen[9]) &&
    new BN(_citizen[10]).eq(citizen[10]) &&
    new BN(_citizen[11]).eq(citizen[11])
  );
};

describe('State', function () {
  const DECIMALS = 18;
  const INITIAL_SUPPLY = new BN('1000000' + '0'.repeat(DECIMALS));
  const PRICE_FULL = new BN('1' + '0'.repeat(16));
  const AWARD = new BN('100' + '0'.repeat(18));
  const NB_TOKENS = new BN('100' + '0'.repeat(18));
  const [owner, dev, admin1, admin2, sentenced, registryFunder, person1, person2, company] = accounts;
  const AGE1 = 40;
  const AGE2 = 70;
  const RETIREMENT_AGE = 67;
  const IS_WORKING = true;
  const IS_SICK = false;

  context('contract construction', function () {
    beforeEach(async function () {
      // 1.create an instance of App to get its address
      this.state = await State.new(owner, PRICE_FULL, { from: dev });
    });

    it('transfers ownership from msg.sender to owner', async function () {
      expect(await this.state.owner()).to.equal(owner);
    });

    it('sovereign() is set to address of owner and casted as payable', async function () {
      const ownerBalanceBeforePayed = await balance.current(owner);
      const amount = ether('1');
      await send.ether(dev, owner, amount);
      expect(await balance.current(owner)).to.be.bignumber.equal(ownerBalanceBeforePayed.add(amount));
    });
  });

  context('getter functions', function () {
    before(async function () {
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    });

    beforeEach(async function () {
      this.state = await State.new(owner, PRICE_FULL, { from: dev });
      this.token = await Token.new(owner, INITIAL_SUPPLY, this.state.address, [this.state.address], { from: dev });
    });

    it('setToken() sets token address during Token construction and getToken gets it', async function () {
      expect(await this.state.getToken(), { from: dev }).to.equal(this.token.address);
    });

    it('price () gets price set during construction', async function () {
      expect(await this.state.price()).to.be.bignumber.equal(PRICE_FULL);
    });

    it('sovereign() gets address of sovereign as owner casted as payable during construction', async function () {
      expect(await this.state.sovereign()).to.equal(owner);
    });
  });

  context('set Admin function', function () {
    beforeEach(async function () {
      this.state = await State.new(owner, PRICE_FULL, { from: dev });
      await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: admin1 });
    });

    it('reverts if setAdmin is not called by sovereign', async function () {
      await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: person1 });
      await expectRevert(this.state.setAdmin(admin1, { from: person1 }), 'Ownable: caller is not the owner');
    });

    it('reverts if the candidate does not have enough to stake', async function () {
      await this.state.denaturalize(admin1, { from: owner });
      await expectRevert(
        this.state.setAdmin(admin1, { from: owner }),
        'candidate does not have enough CTZ to become admin',
      );
    });

    it('sets to true the value corresponding to candidate address in _admins mapping', async function () {
      await this.state.setAdmin(admin1, { from: owner });
      expect(await this.state.checkAdmin(admin1)).to.be.true;
    });
  });

  context('changeHealthStatus function', function () {
    context('check reverts', function () {
      beforeEach(async function () {
        this.state = await State.new(owner, PRICE_FULL, { from: dev });
        await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: admin1 });
        await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: person1 });
        await this.state.setAdmin(admin1, { from: owner });
      });

      it('reverts if changeHealthStatus is not called by an admin', async function () {
        await expectRevert(
          this.state.changeHealthStatus(person1, '0', { from: person1 }),
          'only admin can perform this action',
        );
      });

      it('reverts if changeHealthStatus is called with a health option other than 0,1,2', async function () {
        await expectRevert(
          this.state.changeHealthStatus(person1, '3', { from: admin1 }),
          'Invalid health status choice',
        );
      });
    });

    context('option 0 Died', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.state = await State.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.state.address, [this.state.address], { from: dev });
        await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: admin1 });
        await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: person1 });
        await this.state.setAdmin(admin1, { from: owner });
      });

      it('resets to false the value corresponding to admin address in _admins mapping', async function () {
        await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: admin2 });
        await this.state.setAdmin(admin2, { from: owner });
        this.state.changeHealthStatus(admin1, '0', { from: admin2 });
        expect(await this.state.checkAdmin(admin1)).to.be.false;
      });

      it('resets to 0 all citizen properties', async function () {
        this.state.changeHealthStatus(person1, '0', { from: admin1 });
        const arrayDied = await this.state.getCitizen(person1);
        const arrayNotACitizen = await this.state.getCitizen(person2);
        expect(arrayDied).to.deep.equal(arrayNotACitizen);
      });

      it('transfers tokens from former citizen back to the sovereign', async function () {
        const balanceDied = await this.token.balanceOf(person1);
        const initialBalanceSovereign = await this.token.balanceOf(owner);
        this.state.changeHealthStatus(person1, '0', { from: admin1 });
        expect(await this.token.balanceOf(person1)).to.be.bignumber.equal(new BN(0));
        expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(initialBalanceSovereign.add(balanceDied));
      });
    });

    context('option 1 Healthy', function () {
      beforeEach(async function () {
        this.state = await State.new(owner, PRICE_FULL, { from: dev });
        await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: admin1 });
        await this.state.becomeCitizen(AGE1, IS_WORKING, !IS_SICK, { from: person1 });
        await this.state.setAdmin(admin1, { from: owner });
      });

      it('sets isSick value to false', async function () {
        this.state.changeHealthStatus(person1, '1', { from: admin1 });
        expect(await this.state.getCitizen(person1).isSick).to.be.false;
      });
    });

    context('option 2 Sick', function () {
      beforeEach(async function () {
        this.state = await State.new(owner, PRICE_FULL, { from: dev });
        await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: admin1 });
        await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: person1 });
        await this.state.setAdmin(admin1, { from: owner });
        await this.state.registerCompany(company, { from: admin1 });
        await this.state.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        await this.state.recruit(person1, { from: company });
        await this.state.paySalary(person1, NB_TOKENS);
      });

      it('sets isSick value to true', async function () {
        this.state.changeHealthStatus(person1, '2', { from: admin1 });
        expect(await this.state.getCitizen(person1).isSick).to.be.true;
      });

      it('transfers all health insurance tokens to current account', async function () {
        const currentAccount = await this.state.getCitizen(person1).nbOfCurrentAccountTokens;
        const healthInsurance = await this.state.getCitizen(person1).nbOfHealthInsuranceTokens;
        this.state.changeHealthStatus(person1, '2', { from: admin1 });
        expect(await this.state.getCitizen(person1).nbOfCurrentAccountTokens, 'current account').to.be.bignumber.equal(
          currentAccount.add(healthInsurance),
        );
        expect(
          await this.state.getCitizen(person1).nbOfHealthInsuranceTokens,
          'health insurance',
        ).to.be.bignumber.equal(new BN(0));
      });
    });
  });

  context('changeEmploymentStatus function', function () {});

  context('getRetired function', function () {});

  context('becomeCitizen function and citizen(address) getter', function () {
    before(async function () {
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    });

    beforeEach(async function () {
      this.state = await State.new(owner, PRICE_FULL, { from: dev });
      this.token = await Token.new(owner, INITIAL_SUPPLY, this.state.address, [this.state.address], { from: dev });
    });

    it('creates citizens based on age, sickness and working status', async function () {
      await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: person1 });
      const _current = await time.latest();
      const citizen1 = [
        true,
        constants.ZERO_ADDRESS,
        IS_WORKING,
        IS_SICK,
        new BN(0),
        new BN(0),
        _current.add(new BN((RETIREMENT_AGE - AGE1) * time.duration.weeks(52))),
        new BN(0),
        AWARD,
        new BN(0),
        new BN(0),
        new BN(0),
      ];

      await this.state.becomeCitizen(AGE2, !IS_WORKING, !IS_SICK, { from: person2 });
      const citizen2 = [
        true,
        constants.ZERO_ADDRESS,
        !IS_WORKING,
        !IS_SICK,
        new BN(0),
        new BN(0),
        _current,
        new BN(0),
        AWARD,
        new BN(0),
        new BN(0),
        new BN(0),
      ];

      const _citizen1 = await this.state.getCitizen(person1);
      const _citizen2 = await this.state.getCitizen(person2);

      expect(isSameCitizen(_citizen1, citizen1), 'same citizen1 aged 40, working and not sick').to.be.true;
      expect(isSameCitizen(_citizen2, citizen2), 'same citizen2 aged 70, not working and sick').to.be.true;
      expect(await this.token.balanceOf(person1), 'balance of new citizen1').to.be.bignumber.equal(AWARD);
      expect(await this.token.balanceOf(person2), 'balance of new citizen2').to.be.bignumber.equal(AWARD);
    });
  });

  context('denaturalize function', function () {
    before(async function () {
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    });

    beforeEach(async function () {
      this.state = await State.new(owner, PRICE_FULL, { from: dev });
      this.token = await Token.new(owner, INITIAL_SUPPLY, this.state.address, [this.state.address], { from: dev });
      await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: admin1 });
      await this.state.setAdmin(admin1, { from: owner });
      await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: sentenced });
    });

    it('reverts if denaturalize is not called by an admin', async function () {
      await expectRevert(this.state.denaturalize(sentenced, { from: dev }), 'only admin can perform this action');
    });

    it('reverts if trying to denaturalize the sovereign', async function () {
      await expectRevert(this.state.denaturalize(owner, { from: admin1 }), 'sovereign cannot loose citizenship');
    });

    it('reverts if trying to denaturalize a dead citizen', async function () {
      await this.state.changeHealthStatus(sentenced, '0', { from: admin1 });
      await expectRevert(
        this.state.denaturalize(sentenced, { from: admin1 }),
        'impossible punishment: not an alive citizen',
      );
    });

    it('resets to false the value corresponding to admin address in _admins mapping', async function () {
      await this.state.becomeCitizen(AGE1, IS_WORKING, IS_SICK, { from: admin2 });
      await this.state.setAdmin(admin2, { from: owner });
      await this.state.denaturalize(admin1, { from: admin2 });
      expect(await this.state.checkAdmin(admin1)).to.be.false;
    });

    it('resets to 0 all citizen properties', async function () {
      await this.state.denaturalize(sentenced, { from: admin1 });
      const arraySentenced = await this.state.getCitizen(sentenced);
      const arrayNotACitizen = await this.state.getCitizen(person1);
      expect(arraySentenced).to.deep.equal(arrayNotACitizen);
    });

    it('transfers tokens from former citizen back to the sovereign', async function () {
      const initialBalanceSovereign = await this.token.balanceOf(owner);
      await this.state.denaturalize(sentenced, { from: admin1 });
      expect(await this.token.balanceOf(sentenced)).to.be.bignumber.equal(new BN(0));
      expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(initialBalanceSovereign.add(AWARD));
    });
  });
});
