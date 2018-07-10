const VendingMachine = artifacts.require("OracleVendingMachine");
const Math = artifacts.require("Math");
const CentralizedBugOracle = artifacts.require("CentralizedBugOracle");
const Token = artifacts.require("SolidToken");

contract("Vending Machine", (accounts) => {
  let vendingMachine, masterOracle, token = {};

  const fee = 1000;
  const maker = accounts[3];
  const taker = accounts[4];
  const hash = "QmT4AeWE9Q9EaoyLJiqaZuYQ8mJeq4ZBncjjFH9dQ9uD01";
  const hash2 = "QmT4AeWE9Q9EaoyLJiqaZuYQ8mJeq4ZBncjjFH9dQ9uD02";

  context("Testing contract deployment", async() => {
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
      let _fee = await vendingMachine.fee()
      assert.equal(fee, _fee.toNumber())
    })

    it("Correctly accounts for token credits", async() => {
      let bal = await token.balanceOf(accounts[0]);
      await vendingMachine.checkBalance(accounts[0]);
      let credit = await vendingMachine.balances(accounts[0]);
      assert.equal(bal.toNumber(), credit.toNumber());
    })

    it("Correctly deploys contract using priviledged function", async() =>{
      let bal1 = await token.balanceOf(maker);
      let bal2 = await token.balanceOf(taker);
      await vendingMachine.buyOracleFor(hash, maker, taker);
      let bal3 = await vendingMachine.balances(maker);
      let bal4 = await vendingMachine.balances(taker);
      let or = await vendingMachine.oracleDeployed(maker, taker, 0)

      let oracle = await CentralizedBugOracle.at(or);

      let o = await oracle.owner()
      let m = await oracle.maker()
      let t = await oracle.taker()
      let mc = await oracle.masterCopy();

      assert.equal(bal1.toNumber(), bal3.toNumber() + fee)
      assert.equal(bal2.toNumber(), bal4.toNumber() + fee)
      assert.equal(o, accounts[0]);
      assert.equal(m, maker);
      assert.equal(t, taker);
      assert.equal(mc, masterOracle.address);
    })

    it("Proposes an oracle correcly", async() => {
      let tx = await vendingMachine.buyOracle(hash2, taker, {from: maker});
      let index = tx.logs[0].args.index.toNumber()
      let event = tx.logs[0].event
      assert.equal(event, "OracleProposed")
    })

    it("Accepts an proposal", async() => {
      let tx = await vendingMachine.confirmOracle(maker, 1, { from: taker})
      let event1 = tx.logs[0].event
      let event2 = tx.logs[1].event
      assert.equal(event1, "OracleDeployed")
      assert.equal(event2, "OracleAccepted");
    })

  })

})
