pragma solidity ^0.4.24;

import "./Gnosis/Oracles/Oracle.sol";
import "./Gnosis/Oracles/CentralizedOracle.sol";
import "./Gnosis/Utils/Proxy.sol";
import "./Gnosis/Tokens/Token.sol";
import "./OracleVendingMachineProxy.sol";

//Vending machine Logic goes in this contract
contract OracleVendingMachine is OracleVendingMachineData {

  /*
   *  Modifiers
   */
  modifier isOwner () {
      // Only owner is allowed to proceed
      require(msg.sender == owner);
      _;
  }

  function changeFee(uint _fee) public isOwner {
      fee = _fee;
  }

  function upgradeOracle(address _oracleMasterCopy) public isOwner {
      oracleMasterCopy = Oracle(_oracleMasterCopy);
  }

  function changePaymentToken(address _paymentToken) public isOwner {
      paymentToken = Token(_paymentToken);
  }

  function buyOracle(bytes _ipfsHash) public returns (Oracle oracle){
      require(paymentToken.transferFrom(msg.sender, owner, fee));
      oracle = CentralizedOracle(new CentralizedOracleProxy(oracleMasterCopy, owner, _ipfsHash));
      emit OracleCreation(msg.sender, oracle, _ipfsHash);
  }

}
