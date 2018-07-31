const OracleVendingMachine = artifacts.require('OracleVendingMachine.sol');
const CentralizedBugOracle = artifacts.require('CentralizedBugOracle.sol');

module.exports = function (deployer, network, accounts) {

  const solidTokenAddress = "0xcb65fcd12896d7bfd486e2695396050478fafd3a";
  const fee = 1 * 10**18;

  deployer.deploy(CentralizedBugOracle)
  .then((instance) => {
    console.log("Deployed Centralized Bug Oracle Master copy");
    console.log("CBO address: ", instance.address);
    return deployer.deploy(OracleVendingMachine, fee, solidTokenAddress, CentralizedBugOracle.address)
  })
}
