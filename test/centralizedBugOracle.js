const CentralizedBugOracle = artifacts.require("CentralizedBugOracle");
const CentralizedBugOracleProxy = artifacts.require("CentralizedBugOracleProxy")

contract("OracleBugBounty", (accounts) => {

  let cbo, proxy, masterCopy = {}

  const owner = accounts[0];
  const maker = accounts[3];
  const taker = accounts[4];
  const hash = "QmT4AeWE9Q9EaoyLJiqaZuYQ8mJeq4ZBncjjFH9dQ9uD01";

  before(async() => {
    masterCopy = await CentralizedBugOracle.new()
  })

  context("testing the Oracle Bug Oracle directly", async () => {
    it("Deploys correctly", async() =>{

      cbo = await CentralizedBugOracleProxy.new(masterCopy.address, owner, hash, maker, taker);

      let o = await cbo.owner()
      let m = await cbo.maker()
      let t = await cbo.taker()
      let h = await cbo.ipfsHash()
      let mc = await cbo.masterCopy();

      assert.equal(o, accounts[0]);
      assert.equal(m, maker);
      assert.equal(t, taker);
      assert.equal(web3.toAscii(h), hash)
      assert.equal(mc, masterCopy.address);
    })
  })


})
