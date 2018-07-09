pragma solidity ^0.4.24;

import "./Gnosis/Oracles/Oracle.sol";
//import "./Gnosis/Oracles/CentralizedOracle.sol";
import "./Gnosis/Utils/Proxy.sol";
import "./Gnosis/Utils/Math.sol";
import "./Gnosis/Tokens/Token.sol";
import "./CentralizedBugOracle.sol";

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
  mapping (address => mapping (address => uint256)) public oracleIndexes;
  mapping (address => mapping (address => mapping (uint256 => bool))) public oracleAccepted;
  mapping (address => mapping (address => mapping (uint256 => bool))) public oracleDeployed;

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

  constructor(uint _fee, address _token, address _oracleMasterCopy) public {
    owner = msg.sender;
    fee = _fee;
    paymentToken = Token(_token);
    oracleMasterCopy = Oracle(_oracleMasterCopy);
    open = true;
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
    require(oracleAccepted[maker][taker][oracleIndex]);
    require(!oracleDeployed[maker][taker][oracleIndex]);
    oracle = CentralizedBugOracle(new CentralizedBugOracleProxy(oracleMasterCopy, owner, _ipfsHash, maker, taker));
    oracleDeployed[maker][taker][oracleIndex] = true;
    //emit OracleCreation(msg.sender, oracle, _ipfsHash);
  }

  //POTENTIAL VULNERABILITY IN UNKONWING MAKER
  function confirmOracle(address maker, uint index) public returns(bool) {
    if(balanceChecked[msg.sender]) checkBalance(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(fee);
    require(!oracleAccepted[maker][msg.sender][index]);
    oracleAccepted[maker][msg.sender][index] = true;
  }

  function buyOracle(bytes _ipfsHash, address taker) public whenOpen returns (uint index){
    if(balanceChecked[msg.sender]) checkBalance(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(fee);
    index = oracleIndexes[msg.sender][taker];
  }

  function buyOracleFor(bytes _ipfsHash, address maker, address taker) public whenOpen isOwner{
    if(balanceChecked[maker]) checkBalance(maker);
    if(balanceChecked[taker]) checkBalance(taker);

    balances[maker] = balances[maker].sub(fee);
    balances[taker] = balances[taker].sub(fee);

    oracleAccepted[maker][taker][oracleIndexes[maker][taker]] = true;
    deployOracle(_ipfsHash,maker,taker,oracleIndexes[maker][taker]);
    oracleIndexes[maker][taker] += 1;
  }

  function checkBalance(address holder) public {
    require(!balanceChecked[holder]);
    balances[holder] = paymentToken.balanceOf(holder);
    balanceChecked[holder] = true;
  }

}
