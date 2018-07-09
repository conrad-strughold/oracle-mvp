const VendingMachine = artifacts.require("OracleVendingMachine");
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
    })
  })

})
