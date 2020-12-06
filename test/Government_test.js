/* eslint-disable comma-dangle */
/* eslint-disable no-unused-expressions */
const { contract, accounts } = require('@openzeppelin/test-environment');
const {
  BN,
  singletons,
  constants,
  expectRevert,
  expectEvent,
  balance,
  send,
  ether,
  time,
} = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

/* TODO: update getRetired for enployment
Events */

const Government = contract.fromArtifact('Government');
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
    new BN(_citizen[8]).eq(citizen[8])
  );
};

describe('Government', function () {
  this.timeout(0);
  const DECIMALS = 18;
  const INITIAL_SUPPLY = new BN('1000000' + '0'.repeat(DECIMALS));
  const PRICE_FULL = new BN('1' + '0'.repeat(16));
  const AWARD = new BN('100' + '0'.repeat(18));
  const NB_TOKENS = new BN('100' + '0'.repeat(18));
  const AGE1 = new BN('40');
  const AGE2 = new BN('70');
  const RETIREMENT_AGE = new BN('67');
  const [owner, dev, sentenced, registryFunder, person1, person2, company, company2, hospital] = accounts;

  context('contract construction', function () {
    beforeEach(async function () {
      this.government = await Government.new(owner, PRICE_FULL, { from: dev });
    });

    it('transfers ownership from msg.sender to owner', async function () {
      expect(await this.government.owner()).to.equal(owner);
    });

    it('sets address of owner to _sovereign payable', async function () {
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
      this.government = await Government.new(owner, PRICE_FULL, { from: dev });
      this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
        from: dev,
      });
    });

    it('gets token address set during Token construction', async function () {
      expect(await this.government.getToken(), { from: dev }).to.equal(this.token.address);
    });

    it('gets price of 1 CTZ set during contract construction', async function () {
      expect(await this.government.price()).to.be.bignumber.equal(PRICE_FULL);
    });

    it('gets address of owner (sovereign casted as payable) during contract construction', async function () {
      expect(await this.government.sovereign()).to.equal(owner);
    });
  });

  context('register a hospital', function () {
    beforeEach(async function () {
      this.government = await Government.new(owner, PRICE_FULL, { from: dev });
    });

    it('reverts if registerHospital is not called by sovereign', async function () {
      await expectRevert(
        this.government.registerHospital(hospital, { from: person1 }),
        'Ownable: caller is not the owner',
      );
    });

    it('reverts if the hospital is already registered', async function () {
      await this.government.registerHospital(hospital, { from: owner });
      await expectRevert(
        this.government.registerHospital(hospital, { from: owner }),
        'Government: hospital is already registered',
      );
    });

    it('sets to true the value corresponding to hospital address in _hospitals mapping', async function () {
      await this.government.registerHospital(hospital, { from: owner });
      expect(await this.government.checkHospital(hospital)).to.be.true;
    });

    it('emits an event SetHospital with hospital status changed', async function () {
      const truffleReceipt = await this.government.registerHospital(hospital, { from: owner });
      expectEvent(truffleReceipt, 'SetHospital', {
        hospital: hospital,
        isHospital: true,
      });
    });
  });

  context('unregister a hospital', function () {
    beforeEach(async function () {
      this.government = await Government.new(owner, PRICE_FULL, { from: dev });
    });

    it('reverts if unregisterHospital is not called by sovereign', async function () {
      await expectRevert(
        this.government.unregisterHospital(hospital, { from: person1 }),
        'Ownable: caller is not the owner',
      );
    });

    it('reverts if the hospital is already unregistered', async function () {
      await expectRevert(
        this.government.unregisterHospital(hospital, { from: owner }),
        'Government: hospital is already unregistered',
      );
    });

    it('sets to false the value corresponding to hospital address in _hospitals mapping', async function () {
      await this.government.registerHospital(hospital, { from: owner });
      expect(await this.government.checkHospital(hospital)).to.be.true;
      await this.government.unregisterHospital(hospital, { from: owner });
      expect(await this.government.checkHospital(hospital)).to.be.false;
    });

    it('emits an event SetHospital with hospital status changed', async function () {
      await this.government.registerHospital(hospital, { from: owner });
      const truffleReceipt = await this.government.unregisterHospital(hospital, { from: owner });
      expectEvent(truffleReceipt, 'SetHospital', {
        hospital: hospital,
        isHospital: false,
      });
    });
  });

  context('register a company', function () {
    beforeEach(async function () {
      this.government = await Government.new(owner, PRICE_FULL, { from: dev });
    });

    it('reverts if registerCompany is not called by sovereign', async function () {
      await expectRevert(
        this.government.registerCompany(company, { from: person1 }),
        'Ownable: caller is not the owner',
      );
    });

    it('reverts if the company is already registered', async function () {
      await this.government.registerCompany(company, { from: owner });
      await expectRevert(
        this.government.registerCompany(company, { from: owner }),
        'Government: company is already registered',
      );
    });

    it('sets to true the value corresponding to company address in _companies mapping', async function () {
      await this.government.registerCompany(company, { from: owner });
      expect(await this.government.checkCompany(company)).to.be.true;
    });

    it('emits an event SetCompany with company status changed', async function () {
      const truffleReceipt = await this.government.registerCompany(company, { from: owner });
      expectEvent(truffleReceipt, 'SetCompany', {
        company: company,
        isCompany: true,
      });
    });
  });

  context('unregister a company', function () {
    beforeEach(async function () {
      this.government = await Government.new(owner, PRICE_FULL, { from: dev });
    });

    it('reverts if unregisterCompany is not called by sovereign', async function () {
      await expectRevert(
        this.government.unregisterCompany(company, { from: person1 }),
        'Ownable: caller is not the owner',
      );
    });

    it('reverts if the company is already unregistered', async function () {
      await expectRevert(
        this.government.unregisterCompany(company, { from: owner }),
        'Government: company is already unregistered',
      );
    });

    it('sets to false the value corresponding to company address in _companies mapping', async function () {
      await this.government.registerCompany(company, { from: owner });
      expect(await this.government.checkCompany(company), 'registration').to.be.true;
      await this.government.unregisterCompany(company, { from: owner });
      expect(await this.government.checkCompany(company), 'unregistration').to.be.false;
    });

    it('emits an event SetCompany with company status changed', async function () {
      await this.government.registerCompany(company, { from: owner });
      const truffleReceipt = await this.government.unregisterCompany(company, { from: owner });
      expectEvent(truffleReceipt, 'SetCompany', {
        company: company,
        isCompany: false,
      });
    });
  });

  context('changeHealthStatus function', function () {
    context('check reverts', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person2, gas: 5500000 });
        await this.government.registerHospital(hospital, { from: owner });
      });

      it('reverts if changeHealthStatus is not called by a hospital', async function () {
        await expectRevert(
          this.government.changeHealthStatus(person2, '0', { from: person2 }),
          'Government: only a hospital can perform this action',
        );
      });

      it('reverts if trying to change health of not a citizen', async function () {
        await expectRevert(
          this.government.changeHealthStatus(person1, '0', { from: hospital }),
          'Government: can not change health since not an alive citizen',
        );
      });

      it('reverts if changeHealthStatus is called with a health option other than 0,1,2', async function () {
        await expectRevert(
          this.government.changeHealthStatus(person2, '3', { from: hospital }),
          'revert',
          // 'Invalid health status choice',
        );
      });
    });

    context('option 0 Died', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person1 });
        await this.government.registerHospital(hospital, { from: owner });
      });

      it('resets to 0 all citizen properties', async function () {
        await this.government.changeHealthStatus(person1, '0', { from: hospital });
        const arrayDied = await this.government.getCitizen(person1);
        const arrayNotACitizen = await this.government.getCitizen(person2);
        expect(arrayDied).to.deep.equal(arrayNotACitizen);
      });

      it('transfers tokens from former citizen back to the sovereign', async function () {
        const balanceDied = await this.token.balanceOf(person1);
        const initialBalanceSovereign = await this.token.balanceOf(owner);
        await this.government.changeHealthStatus(person1, '0', { from: hospital });
        expect(await this.token.balanceOf(person1)).to.be.bignumber.equal(new BN('0'));
        expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(initialBalanceSovereign.add(balanceDied));
      });

      it('emits an event LostCitizenship(former Citizen address)', async function () {
        const truffleReceipt = await this.government.changeHealthStatus(person1, '0', { from: hospital });
        expectEvent(truffleReceipt, 'LostCitizenship', { citizenAddress: person1 });
      });
    });

    context('option 1 Healthy', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person1 });
        await this.government.registerHospital(hospital, { from: owner });
      });

      it('sets isSick value to false', async function () {
        await this.government.changeHealthStatus(person1, '1', { from: hospital });
        const pers1 = await this.government.getCitizen(person1);
        expect(pers1.isSick).to.be.false;
      });

      it('emits an event UpdatedHealth with citizen properties changed', async function () {
        const truffleReceipt = await this.government.changeHealthStatus(person1, '1', { from: hospital });
        const pers1 = await this.government.getCitizen(person1);
        expectEvent(truffleReceipt, 'UpdatedHealth', {
          citizenAddress: person1,
          isSick: false,
          currentTokens: pers1.currentTokens,
          healthTokens: pers1.healthTokens,
        });
      });
    });

    context('option 2 Sick', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.registerCompany(company, { from: owner });
        await this.government.becomeCitizen(AGE1, { from: person1 });
        await this.government.registerHospital(hospital, { from: owner });
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        await this.government.changeEmploymentStatus(person1, { from: company });
        await this.government.paySalary(person1, NB_TOKENS, { from: company });
      });

      it('sets isSick value to true', async function () {
        await this.government.changeHealthStatus(person1, '2', { from: hospital });
        const pers1 = await this.government.getCitizen(person1);
        expect(pers1.isSick).to.be.true;
      });

      it('transfers all health insurance tokens to current account', async function () {
        const pers1 = await this.government.getCitizen(person1);
        const currentAccount = new BN(pers1.currentTokens);
        const healthInsurance = new BN(pers1.healthTokens);
        await this.government.changeHealthStatus(person1, '2', { from: hospital });
        const _pers1 = await this.government.getCitizen(person1);
        expect(_pers1.currentTokens, 'current account').to.be.bignumber.equal(currentAccount.add(healthInsurance));
        expect(_pers1.healthTokens, 'health insurance').to.be.bignumber.equal(new BN('0'));
      });

      it('emits an event UpdatedHealth with citizen properties changed', async function () {
        const truffleReceipt = await this.government.changeHealthStatus(person1, '2', { from: hospital });
        const pers1 = await this.government.getCitizen(person1);
        expectEvent(truffleReceipt, 'UpdatedHealth', {
          citizenAddress: person1,
          isSick: true,
          currentTokens: pers1.currentTokens,
          healthTokens: pers1.healthTokens,
        });
      });
    });
  });

  context('changeEmploymentStatus function', function () {
    context('check revert', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person1 });
        await this.government.registerCompany(company, { from: owner });
      });

      it('reverts if changeEmploymentStatus is not called by a company', async function () {
        await expectRevert(
          this.government.changeEmploymentStatus(person1, { from: person1 }),
          'Government: only a company can perform this action',
        );
      });

      it('reverts if changeEmploymentStatus is called by wrong company', async function () {
        await this.government.changeEmploymentStatus(person1, { from: company });
        await this.government.registerCompany(company2, { from: owner });
        await expectRevert(
          this.government.changeEmploymentStatus(person1, { from: company2 }),
          'Government: not working for this company',
        );
      });

      it('reverts if trying to change employment of not a citizen', async function () {
        await expectRevert(
          this.government.changeEmploymentStatus(person2, { from: company }),
          'Government: can not change employment since not an alive citizen',
        );
      });
    });

    context('change to working', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person1 });
        await this.government.registerCompany(company, { from: owner });
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
      });

      it('sets isWorking value to true', async function () {
        await this.government.changeEmploymentStatus(person1, { from: company });
        const pers1 = await this.government.getCitizen(person1);
        expect(pers1.isWorking).to.be.true;
      });

      it('sets employer', async function () {
        await this.government.changeEmploymentStatus(person1, { from: company });
        const pers1 = await this.government.getCitizen(person1);
        expect(pers1.employer).to.be.equal(company);
      });

      it('emits an event UpdatedEmployment with citizen properties changed', async function () {
        const truffleReceipt = await this.government.changeEmploymentStatus(person1, { from: company });
        const pers1 = await this.government.getCitizen(person1);
        expectEvent(truffleReceipt, 'UpdatedEmployment', {
          citizenAddress: person1,
          employer: company,
          isWorking: true,
          currentTokens: pers1.currentTokens,
          unemploymentTokens: pers1.unemploymentTokens,
        });
      });
    });

    context('change to unemployed', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person1 });
        await this.government.registerCompany(company, { from: owner });
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        await this.government.changeEmploymentStatus(person1, { from: company });
        await this.government.paySalary(person1, NB_TOKENS, { from: company });
      });

      it('sets isWorking value to false', async function () {
        await this.government.changeEmploymentStatus(person1, { from: company });
        const pers1 = await this.government.getCitizen(person1);
        expect(pers1.isWorking).to.be.false;
      });

      it('sets as employer address 0', async function () {
        await this.government.changeEmploymentStatus(person1, { from: company });
        const pers1 = await this.government.getCitizen(person1);
        expect(pers1.employer).to.be.equal(constants.ZERO_ADDRESS);
      });
      // add require change to unemployment if already working for company

      it('transfers all unemployment tokens to current account', async function () {
        const pers1 = await this.government.getCitizen(person1);
        const currentAccount = new BN(pers1.currentTokens);
        const unemploymentInsurance = new BN(pers1.unemploymentTokens);
        await this.government.changeEmploymentStatus(person1, { from: company });
        const _pers1 = await this.government.getCitizen(person1);
        expect(_pers1.currentTokens, 'current account').to.be.bignumber.equal(
          currentAccount.add(unemploymentInsurance),
        );
        expect(_pers1.unemploymentTokens, 'unemployment insurance').to.be.bignumber.equal(new BN('0'));
      });

      it('emits an event UpdatedEmployment with citizen properties changed', async function () {
        const pers1 = await this.government.getCitizen(person1);
        const current = new BN(pers1.currentTokens);
        const unemploymentInsurance = new BN(pers1.unemploymentTokens);
        const truffleReceipt = await this.government.changeEmploymentStatus(person1, { from: company });
        expectEvent(truffleReceipt, 'UpdatedEmployment', {
          citizenAddress: person1,
          employer: constants.ZERO_ADDRESS,
          isWorking: false,
          currentTokens: current.add(unemploymentInsurance),
          unemploymentTokens: new BN('0'),
        });
      });
    });
  });

  context('getRetired function', function () {
    context('check revert', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person1 });
      });

      it('reverts if getRetired is not called by a citizen alive', async function () {
        await this.government.registerHospital(hospital, { from: owner });
        await this.government.changeHealthStatus(person1, '0', { from: hospital });
        await expectRevert(
          this.government.getRetired({ from: person1 }),
          'Government: only alive citizens can perform this action',
        );
      });

      it('reverts if getRetired is called too early', async function () {
        await this.government.registerCompany(company, { from: owner });
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        await this.government.changeEmploymentStatus(person1, { from: company });
        await this.government.paySalary(person1, NB_TOKENS, { from: company });
        await expectRevert(this.government.getRetired({ from: person1 }), 'Government: retirement possible only at 67');
        await time.increase(time.duration.years(27));
        const pers1 = await this.government.getCitizen(person1);
        expect(pers1.retirementTokens, 'retirement tokens person 1 before').to.be.bignumber.equal(
          NB_TOKENS.div(new BN('10')),
        );
        await this.government.getRetired({ from: person1 });
        const _pers1 = await this.government.getCitizen(person1);
        expect(_pers1.retirementTokens, 'retirement tokens person 1 after').to.be.bignumber.equal(new BN('0'));
      });
    });

    context('change of working status and transfer of tokens', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE2, { from: person2 });
        await this.government.registerCompany(company, { from: owner });
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        await this.government.changeEmploymentStatus(person2, { from: company });
        await this.government.paySalary(person2, NB_TOKENS, { from: company });
      });

      it('sets isWorking value to false', async function () {
        await this.government.getRetired({ from: person2 });
        const pers2 = await this.government.getCitizen(person2);
        expect(pers2.isWorking).to.be.false;
      });

      it('sets as employer address 0', async function () {
        await this.government.getRetired({ from: person2 });
        const pers2 = await this.government.getCitizen(person2);
        expect(pers2.employer).to.be.equal(constants.ZERO_ADDRESS);
      });

      it('transfers all retirement and unemployment tokens to current account', async function () {
        const pers2 = await this.government.getCitizen(person2);
        const currentAccount = new BN(pers2.currentTokens);
        const retirementInsurance = new BN(pers2.retirementTokens);
        const unemploymentInsurance = new BN(pers2.unemploymentTokens);
        const _addedAmount = retirementInsurance.add(unemploymentInsurance);
        await this.government.getRetired({ from: person2 });
        const _pers2 = await this.government.getCitizen(person2);
        expect(_pers2.currentTokens, 'current account').to.be.bignumber.equal(currentAccount.add(_addedAmount));
        expect(_pers2.retirementTokens, 'retirement insurance').to.be.bignumber.equal(new BN('0'));
        expect(_pers2.unemploymentTokens, 'unemployment insurance').to.be.bignumber.equal(new BN('0'));
      });

      it('emits an event Retired with citizen properties changed', async function () {
        const pers2 = await this.government.getCitizen(person2);
        const current = new BN(pers2.currentTokens);
        const unemploymentInsurance = new BN(pers2.unemploymentTokens);
        const retirementInsurance = new BN(pers2.retirementTokens);
        const _addedAmount = unemploymentInsurance.add(retirementInsurance);
        const truffleReceipt = await this.government.getRetired({ from: person2 });
        expectEvent(truffleReceipt, 'Retired', {
          citizenAddress: person2,
          employer: constants.ZERO_ADDRESS,
          isWorking: false,
          currentTokens: current.add(_addedAmount),
          unemploymentTokens: new BN('0'),
          retirementTokens: new BN('0'),
        });
      });
    });
  });

  context('becomeCitizen function', function () {
    before(async function () {
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    });

    beforeEach(async function () {
      this.government = await Government.new(owner, PRICE_FULL, { from: dev });
      this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
        from: dev,
      });
    });

    it('creates citizens based on age', async function () {
      await this.government.becomeCitizen(AGE1, { from: person1 });
      const _current1 = await time.latest();
      const citizen1 = [
        true,
        constants.ZERO_ADDRESS,
        false,
        false,
        _current1.add(new BN((RETIREMENT_AGE - AGE1) * time.duration.weeks(52))),
        AWARD,
        new BN('0'),
        new BN('0'),
        new BN('0'),
      ];

      await this.government.becomeCitizen(AGE2, { from: person2 });
      const _current2 = await time.latest();
      const citizen2 = [
        true,
        constants.ZERO_ADDRESS,
        false,
        false,
        _current2,
        AWARD,
        new BN('0'),
        new BN('0'),
        new BN('0'),
      ];

      const _citizen1 = await this.government.getCitizen(person1);
      const _citizen2 = await this.government.getCitizen(person2);

      expect(isSameCitizen(_citizen1, citizen1), 'same citizen1 aged 40').to.be.true;
      expect(isSameCitizen(_citizen2, citizen2), 'same citizen2 aged 70').to.be.true;
      expect(await this.token.balanceOf(person1), 'balance of new citizen1').to.be.bignumber.equal(AWARD);
      expect(await this.token.balanceOf(person2), 'balance of new citizen2').to.be.bignumber.equal(AWARD);
    });
  });

  context('denaturalize function', function () {
    before(async function () {
      this.erc1820 = await singletons.ERC1820Registry(registryFunder);
    });

    beforeEach(async function () {
      this.government = await Government.new(owner, PRICE_FULL, { from: dev });
      this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
        from: dev,
      });
      await this.government.becomeCitizen(AGE1, { from: sentenced });
    });

    it('reverts if denaturalize is not called by the sovereign', async function () {
      await expectRevert(this.government.denaturalize(sentenced, { from: dev }), 'Ownable: caller is not the owner');
    });

    it('reverts if trying to denaturalize the sovereign', async function () {
      await expectRevert(
        this.government.denaturalize(owner, { from: owner }),
        'Government: sovereign cannot loose citizenship',
      );
    });

    it('reverts if trying to denaturalize a dead citizen', async function () {
      await this.government.registerHospital(hospital, { from: owner });
      await this.government.changeHealthStatus(sentenced, '0', { from: hospital });
      await expectRevert(
        this.government.denaturalize(sentenced, { from: owner }),
        'Government: impossible punishment since not an alive citizen',
      );
    });

    it('resets to 0 all citizen properties', async function () {
      await this.government.denaturalize(sentenced, { from: owner });
      const arraySentenced = await this.government.getCitizen(sentenced);
      const arrayNotACitizen = await this.government.getCitizen(person1);
      expect(arraySentenced).to.deep.equal(arrayNotACitizen);
    });

    it('transfers tokens from former citizen back to the sovereign', async function () {
      const initialBalanceSovereign = await this.token.balanceOf(owner);
      await this.government.denaturalize(sentenced, { from: owner });
      expect(await this.token.balanceOf(sentenced)).to.be.bignumber.equal(new BN('0'));
      expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(initialBalanceSovereign.add(AWARD));
    });

    it('emits an event LostCitizenship(former Citizen address)', async function () {
      const truffleReceipt = await this.government.denaturalize(sentenced, { from: owner });
      expectEvent(truffleReceipt, 'LostCitizenship', { citizenAddress: sentenced });
    });
  });

  context('buyTokens function', function () {
    context('check revert', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
      });

      it('reverts if buyTokens is not called by a company', async function () {
        await expectRevert(
          this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') }),
          'Government: only a company can perform this action',
        );
      });

      it('reverts if msg.value is less than 1 wei', async function () {
        await this.government.registerCompany(company, { from: owner });
        await expectRevert(
          this.government.buyTokens(NB_TOKENS, { from: company, value: new BN('0') }),
          'Government: minimum 1 wei',
        );
      });

      it('reverts if nbTokens is too low to be bought', async function () {
        await this.government.registerCompany(company, { from: owner });
        await expectRevert(
          this.government.buyTokens(new BN('99'), { from: company, value: ether('1') }),
          'Government: minimum 100 tokens',
        );
      });

      it('reverts if msg.value is too low for nbTokens', async function () {
        await this.government.registerCompany(company, { from: owner });
        await expectRevert(
          this.government.buyTokens(NB_TOKENS.add(new BN('1000')), { from: company, value: ether('1') }),
          'Government: not enough Ether to purchase this number of tokens',
        );
      });
    });

    context('transfer of tokens and ether', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.registerCompany(company, { from: owner });
      });

      it('transfers tokens to company', async function () {
        const balanceTokensCompany = await this.token.balanceOf(company);
        const balanceTokensSovereign = await this.token.balanceOf(owner);
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        expect(await this.token.balanceOf(company)).to.be.bignumber.equal(balanceTokensCompany.add(NB_TOKENS));
        expect(await this.token.balanceOf(owner)).to.be.bignumber.equal(balanceTokensSovereign.sub(NB_TOKENS));
      });

      it('transfers ether to sovereign', async function () {
        const balanceEtherSovereign = await balance.current(owner);
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        expect(await balance.current(owner)).to.be.bignumber.equal(balanceEtherSovereign.add(ether('1')));
      });

      it('transfers remaining ether back to company', async function () {
        const balanceEtherCompany = await balance.current(company);
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('2') });
        // PRICE_FULL is above real gas price
        expect(await balance.current(company)).to.be.bignumber.above(
          balanceEtherCompany.sub(ether('1').add(PRICE_FULL)),
        );
      });
    });
  });

  context('paySalary function', function () {
    context('check revert', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person1 });
        await this.government.registerCompany(company, { from: owner });
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        await this.government.changeEmploymentStatus(person1, { from: company });
      });

      it('reverts if paySalary is not called by a company', async function () {
        await expectRevert(
          this.government.paySalary(person1, NB_TOKENS, { from: person1 }),
          'Government: only a company can perform this action',
        );
      });

      it('reverts if paySalary is called by wrong company', async function () {
        await this.government.registerCompany(company2, { from: owner });
        await expectRevert(
          this.government.paySalary(person1, NB_TOKENS, { from: company2 }),
          'Government: not an employee of this company',
        );
      });

      it('reverts if company has insufficient funds', async function () {
        await expectRevert(
          this.government.paySalary(person1, NB_TOKENS.add(new BN('1')), { from: company }),
          'Government: company balance is less than the amount',
        );
      });
    });

    context('transfer of tokens and update accounts', function () {
      before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(registryFunder);
      });

      beforeEach(async function () {
        this.government = await Government.new(owner, PRICE_FULL, { from: dev });
        this.token = await Token.new(owner, INITIAL_SUPPLY, this.government.address, [this.government.address], {
          from: dev,
        });
        await this.government.becomeCitizen(AGE1, { from: person1 });
        await this.government.registerCompany(company, { from: owner });
        await this.government.buyTokens(NB_TOKENS, { from: company, value: ether('1') });
        await this.government.changeEmploymentStatus(person1, { from: company });
      });

      it('transfers tokens to employee', async function () {
        const balanceTokensCompany = await this.token.balanceOf(company);
        const balanceTokensEmployee = await this.token.balanceOf(person1);
        await this.government.paySalary(person1, NB_TOKENS, { from: company });
        expect(await this.token.balanceOf(company), 'balance company').to.be.bignumber.equal(
          balanceTokensCompany.sub(NB_TOKENS),
        );
        expect(await this.token.balanceOf(person1), 'balance employee').to.be.bignumber.equal(
          balanceTokensEmployee.add(NB_TOKENS),
        );
      });

      it('updates employee accounts', async function () {
        const pers1 = await this.government.getCitizen(person1);
        const currentAccount = new BN(pers1.currentTokens);
        const healthInsurance = new BN(pers1.healthTokens);
        const unemploymentInsurance = new BN(pers1.unemploymentTokens);
        const retirementInsurance = new BN(pers1.retirementTokens);
        await this.government.paySalary(person1, NB_TOKENS, { from: company });
        const _partSalary = NB_TOKENS.div(new BN('10'));
        const _pers1 = await this.government.getCitizen(person1);
        expect(_pers1.currentTokens, 'current account').to.be.bignumber.equal(
          currentAccount.add(NB_TOKENS.sub(_partSalary.mul(new BN('3')))),
        );
        expect(_pers1.healthTokens, 'health insurance').to.be.bignumber.equal(healthInsurance.add(_partSalary));
        expect(_pers1.unemploymentTokens, 'unemployment insurance').to.be.bignumber.equal(
          unemploymentInsurance.add(_partSalary),
        );
        expect(_pers1.retirementTokens, 'retirement insurance').to.be.bignumber.equal(
          retirementInsurance.add(_partSalary),
        );
      });

      it('emits an event Paid with citizen properties changed', async function () {
        const pers1 = await this.government.getCitizen(person1);
        const current = new BN(pers1.currentTokens);
        const healthInsurance = new BN(pers1.healthTokens);
        const unemploymentInsurance = new BN(pers1.unemploymentTokens);
        const retirementInsurance = new BN(pers1.retirementTokens);
        const _partSalary = NB_TOKENS.div(new BN('10'));
        const _addedCurrent = NB_TOKENS.sub(_partSalary.mul(new BN('3')));
        const truffleReceipt = await this.government.paySalary(person1, NB_TOKENS, { from: company });
        expectEvent(truffleReceipt, 'Paid', {
          citizenAddress: person1,
          amount: NB_TOKENS,
          employer: company,
          currentTokens: current.add(_addedCurrent),
          healthTokens: healthInsurance.add(_partSalary),
          unemploymentTokens: unemploymentInsurance.add(_partSalary),
          retirementTokens: retirementInsurance.add(_partSalary),
        });
      });
    });
  });
});
