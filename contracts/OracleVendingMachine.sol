pragma solidity ^0.4.24;

import "./Gnosis/Oracles/Oracle.sol";
import "./Gnosis/Oracles/CentralizedOracle.sol";
import "./Gnosis/Utils/Proxy.sol";
import "./Gnosis/Utils/Math.sol";
import "./Gnosis/Tokens/Token.sol";
import "./OracleVendingMachineProxy.sol";

//Vending machine Logic goes in this contract
contract OracleVendingMachine {
  using Math for uint256;

  /*
   *  Storage
   */
  address public owner;
  uint public fee;
  Oracle oracleMasterCopy;
  Token public paymentToken;
  bool open;


  mapping (address => uint256) public balances;
  mapping (address => bool) public balanceChecked;
  mapping (address => (address => uint256) public oracleIndexes;
  mapping (address => (address => (uint256 => bool)) public oracleAccepted;
  mapping (address => (address => (uint256 => bool)) public oracleDeployed;

  /*
   *  Modifiers
   */
  modifier isOwner () {
      // Only owner is allowed to proceed
      require(msg.sender == owner);
      _;
  }

  modifier whenOpen() {
    require(open);
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

  function modifyOpenStatus(bool status) public isOwner {
    open = status;
  }

  function deployOracle(bytes _ipfsHash, address maker, address taker, uint256 oracleIndex) internal returns(Oracle oracle){
    require(oracleAccepted[maker][taker][id]);
    require(!oracleDeployed[maker][taker][id])
    oracle = CentralizedOracle(new CentralizedOracleProxy(oracleMasterCopy, owner, _ipfsHash));
    oracleDeployed[maker][taker][id] = true;
    emit OracleCreation(msg.sender, oracle, _ipfsHash);
  }

  //POTENTIAL VULNERABILITY IN UNKONWING MAKER
  function confirmOracle(address maker, uint index) public returns(bool) {
    if(balanceChecked[msg.sender]) checkBalance();
    require(balances[msg.sender] = balances[msg.sender].sub(fee));
    require(!oracleAccepted[maker][msg.sender][index]);
    oracleAccepted[maker][msg.sneder][index] = true;
  }

  function buyOracle(bytes _ipfsHash, address taker) public returns (uint index){
    if(balanceChecked[msg.sender]) checkBalance();
    require(balances[msg.sender] = balances[msg.sender].sub(fee));
    index = oracleIndexes[msg.sender][taker];
  }

  function buyOracleFor(bytes _ipfsHash, address maker, address taker) public isOwner (){
    if(balanceChecked[maker]) checkBalance();
    if(balanceChecked[taker]) checkBalance();

    require(balances[maker] = balances[maker].sub(fee));
    require(balances[taker] = balances[taker].sub(fee));

    oracleAccepted[maker][taker][oracleIndexes[maker][taker]] = true;
    deployOracle(_ipfsHash,maker,taker,oracleIndex);
    oracleIndexes[maker][taker] += 1;
  }

  function checkBalance(address holder) public {
    require(!balanceChecked[holder]);
    balances[holder] = paymentToken.balanceOf(holder);
    balanceChecked[holder] = true;
  }

}
