pragma solidity ^0.4.24;
import "../Oracles/Oracle.sol";
import "../Oracles/CentralizedOracle.sol";
import "../Utils/Proxy.sol";
import "../Tokens/Token.sol";

contract OracleVendingMachineData is Proxied {

  /*
   *  Events
   */
  event OracleCreation(address indexed creator, Oracle centralizedOracle, bytes ipfsHash);

  /*
   *  Storage
   */
  address public owner;
  uint public fee;
  Oracle o racleMasterCopy;
  Token public paymentToken;

}

// BASIC PROXY - ISN'T UPGRADABLE YET
contract OracleVendingMachineProxy is Proxy, OracleVendingMachineData{

  contructor(address _proxied) Proxy(_proxied){
    owner = msg.sender;
  }

}

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
      oracleMasterCopy = _oracleMasterCopy;
  }

  function changePaymentToken(address _paymentToken) public isOwner {
      paymentToken = _paymentToken;
  }

  function buyOracle(bytes _ipfsHash) public returns (Oracle oracle){
      require(token.transferFrom(msg.sender, owner, fee));
      oracle = CentralizedOracle(new CentralizedOracleProxy(oracleMasterCopy, owner, _ipfsHash));
      emit OracleCreation(msg.sender, oracle, _ipfsHash);
  }

}
