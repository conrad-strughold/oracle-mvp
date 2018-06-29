pragma solidity ^0.4.24;
import "./Gnosis/Oracles/Oracle.sol";
import "./Gnosis/Oracles/CentralizedOracle.sol";
import "./Gnosis/Utils/Proxy.sol";
import "./Gnosis/Tokens/Token.sol";

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
  Oracle oracleMasterCopy;
  Token public paymentToken;

}

// BASIC PROXY - ISN'T UPGRADABLE YET
contract OracleVendingMachineProxy is Proxy, OracleVendingMachineData{

  constructor(address _proxied) Proxy(_proxied){
    owner = msg.sender;
  }

}
