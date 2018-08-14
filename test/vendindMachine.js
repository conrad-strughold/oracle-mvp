//import assertRevert from './helpers/assertRevert';

const VendingMachine = artifacts.require("OracleVendingMachine");
const CentralizedBugOracle = artifacts.require("CentralizedBugOracle");
const Token = artifacts.require("SolidToken");

const assertRevert = async promise => {
  try {
    await promise;
    assert.fail('Expected revert not received');
  } catch (error) {
    const revertFound = error.message.search('revert') >= 0;
    assert(revertFound, `Expected "revert", got ${error} instead`);
  }
};

const setupToken = async(holders, amount) => {
  let token = await Token.new();
  await token.setTransferEnablingDate(2);
  await token.enableTransfer();
  for (let j = 0;j < holders.length; j++) {
    await token.transfer(holders[j], amount)
  }
  return token;
}

contract("Vending Machine", (accounts) => {
  let vendingMachine, masterOracle, token = {};

  const fee = 1000;
  const maker = accounts[3];
  const taker = accounts[4];
  const hash = "QmT4AeWE9Q9EaoyLJiqaZuYQ8mJeq4ZBncjjFH9dQ9uD01";
  const hash2 = "QmT4AeWE9Q9EaoyLJiqaZuYQ8mJeq4ZBncjjFH9dQ9uD02";

  context("Testing Basic function flows", async() => {
    before(async() => {
      masterOracle = await CentralizedBugOracle.new();
      token = await Token.new();
      await token.setTransferEnablingDate(2);
      await token.enableTransfer();
      await token.transfer(maker, 40000)
      await token.transfer(taker, 40000)
    })

    it("Deplys correctly", async() => {
      vendingMachine = await VendingMachine.new(fee, token.address, masterOracle.address);
      let _fee = await vendingMachine.fee();

      assert.equal(fee, _fee.toNumber())
    })

    it("Correctly accounts for token credits", async() => {
      let bal = await token.balanceOf.call(accounts[0]);
      await vendingMachine.checkBalance(accounts[0]);
      let credit = await vendingMachine.balances(accounts[0]);
      assert.equal(credit.toNumber(), bal.toNumber());
    })

    it("Fails to check for already checked balance", async() => {
      await assertRevert(vendingMachine.checkBalance(accounts[0]));
    })

    it("Correctly deploys contract using priviledged function", async() =>{
      let bal1 = await token.balanceOf.call(maker);
      let bal2 = await token.balanceOf.call(taker);
      await vendingMachine.buyOracleFor(hash, maker, taker);
      let bal3 = await vendingMachine.balances(maker);
      let bal4 = await vendingMachine.balances(taker);
      let or = await vendingMachine.oracleDeployed(maker, taker, 0);
      let oracle = await CentralizedBugOracle.at(or);

      let o = await oracle.owner()
      let m = await oracle.maker()
      let t = await oracle.taker()
      let h = await oracle.ipfsHash()
      let mc = await oracle.masterCopy();

      assert.equal(bal1.toNumber(), bal3.toNumber() + fee)
      assert.equal(bal2.toNumber(), bal4.toNumber() + fee)
      assert.equal(o, accounts[0]);
      assert.equal(m, maker);
      assert.equal(t, taker);
      assert.equal(web3.toAscii(h), hash)
      assert.equal(mc, masterOracle.address);
    })

    it("Proposes an oracle correcly", async() => {
      let tx = await vendingMachine.buyOracle(hash2, taker, {from: maker});
      let index = tx.logs[0].args.index.toNumber()
      let event = tx.logs[0].event
      let or = await vendingMachine.oracleProposed(maker, taker, index);
      assert.equal(web3.toAscii(or[0]), hash2);
      assert.equal(event, "OracleProposed")
    })

    it("Accepts an proposal", async() => {
      let tx = await vendingMachine.confirmOracle(maker, 1, { from: taker})
      let event1 = tx.logs[0].event
      let event2 = tx.logs[1].event
      let or = await vendingMachine.oracleDeployed(maker, taker, 1);
      let oracle = await CentralizedBugOracle.at(or);

      let o = await oracle.owner()
      let m = await oracle.maker()
      let t = await oracle.taker()
      let h = await oracle.ipfsHash()
      let mc = await oracle.masterCopy();

      assert.equal(o, accounts[0]);
      assert.equal(m, maker);
      assert.equal(t, taker);
      assert.equal(web3.toAscii(h), hash2)
      assert.equal(mc, masterOracle.address);

      assert.equal(event1, "OracleDeployed")
      assert.equal(event2, "OracleAccepted");
    })

    it("Fails to revoke already deployed oracle", async () => {
      let index = 1;
      await assertRevert(vendingMachine.revokeOracle(taker, index, {from: maker}))
    })

    it("Revokens an Oracle", async () => {
      let tx = await vendingMachine.buyOracle(hash2, taker, {from: maker});
      let index = tx.logs[0].args.index.toNumber();
      await vendingMachine.revokeOracle(taker, index, {from: maker});
      let or = await vendingMachine.oracleProposed(maker, taker, index);
      assert.equal(or[0], '0x');
      assert.equal(or[1], '0x0000000000000000000000000000000000000000');
      assert.equal(or[2].toNumber(), 0);
    })
  })

  context("Testing alternative branches", async() => {
    let newTaker = accounts[5]
    let newMaker = accounts[6]
    before(async() => {
      masterOracle = await CentralizedBugOracle.new();
      token = await Token.new();
      await token.setTransferEnablingDate(2);
      await token.enableTransfer();
      await token.transfer(newMaker, 40000)
      await token.transfer(newTaker, 40000)
      vendingMachine = await VendingMachine.new(fee, token.address, masterOracle.address);
    })

    it("Fails to deploy vending machinewith wrong parameters", async() => {
      await assertRevert(VendingMachine.new(fee, token.address, "0x0"))
    })

    it("Fails to revoke non-proposed deployed oracle", async () => {
      let index = 0;
      await assertRevert(vendingMachine.revokeOracle(newTaker, index, {from: newMaker}))
    })

    it("Correctly verify balance during the buying process", async () => {
      let tx = await vendingMachine.buyOracle(hash, newTaker, {from: newMaker});
      let bal1 = await token.balanceOf.call(newMaker);
      let bal3 = await vendingMachine.balances(newMaker);
      assert.equal(bal1.toNumber(), bal3.toNumber() + fee)
    })

    it("Fails to confirm non-proposed oracle", async()=>{
      await assertRevert(vendingMachine.confirmOracle(newMaker, 5, {from: newTaker}));
    })

    it("Correctly checks taker balance when confirming oracle", async() => {
      let tx = await vendingMachine.confirmOracle(newMaker, 0,{from: newTaker});
      let bal1 = await token.balanceOf.call(newTaker);
      let bal3 = await vendingMachine.balances(newTaker);
      assert.equal(bal1.toNumber(), bal3.toNumber() + fee)
    })

    it("Refuses transactions when closed", async ()=> {
      await vendingMachine.modifyOpenStatus(false);
      await assertRevert(vendingMachine.buyOracleFor(hash, newMaker, newTaker))
    })

  })

  context("Configuring vending machine", async() => {
    before(async()=>{
      masterOracle = await CentralizedBugOracle.new();
      token = await setupToken([maker, taker], 4000);
      vendingMachine = await VendingMachine.new(fee, token.address, masterOracle.address);
    })

    it("Correctly changes the fee", async() => {
      let newFee = 2000
      await vendingMachine.changeFee(newFee);
      let f = await vendingMachine.fee();
      assert.equal(f.toNumber(), newFee);
    })

    it("Fails to update fee if sender is not owner", async() => {
      let newFee = 2000;
      await assertRevert(vendingMachine.changeFee(newFee, {from: accounts[9]}));
    })

    it("Correctly changes the payment token", async() => {
      let newToken = await setupToken([], 3000);
      await vendingMachine.changePaymentToken(newToken.address);
      let t = await vendingMachine.paymentToken()
      assert.equal(t, newToken.address);
    })

    it("Fails to update to non-valid payment token", async() => {
      await assertRevert(vendingMachine.changePaymentToken("0x0"));
    })

    it("Correctly changes the mastercopy", async() => {
      let newMaster = await CentralizedBugOracle.new();
      await vendingMachine.upgradeOracle(newMaster.address);
      let mc = await vendingMachine.oracleMasterCopy()
      assert.equal(mc, newMaster.address);
    })

    it("Fails to update to non-valid mastercopy", async() => {
      await assertRevert(vendingMachine.upgradeOracle("0x0"));
    })

    it("Correctly closes the vending machine", async () => {
      await vendingMachine.modifyOpenStatus(false);
      let status = await vendingMachine.open();
      assert.isFalse(status);
    })

    it("Correctly opens the vending machine", async () => {
      await vendingMachine.modifyOpenStatus(true);
      let status = await vendingMachine.open();
      assert.isTrue(status);
    })

  })

})
