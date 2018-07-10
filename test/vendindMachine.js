const VendingMachine = artifacts.require("OracleVendingMachine");
const Math = artifacts.require("Math");
const CentralizedBugOracle = artifacts.require("CentralizedBugOracle");
const Token = artifacts.require("SolidToken");

contract("Vending Machine", (accounts) => {
  let vendingMachine, masterOracle, token = {};

  const fee = 1000;

  context("Testing contract deployment", async() => {
    before(async() => {
      masterOracle = await CentralizedBugOracle.new();
      token = await Token.new();
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

  })

})
