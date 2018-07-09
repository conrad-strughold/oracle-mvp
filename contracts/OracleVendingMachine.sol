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
   *  events
   */

  event OracleProposed(address maker, address taker, uint256 index, bytes hash);
  event OracleAccepted(address maker, address taker, uint256 index, bytes hash);
  event OracleDeployed(address maker, address taker, uint256 index, bytes hash, address oracle);
  event OracleRevoked(address maker, address taker, uint256 index, bytes hash);

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
  mapping (address => mapping (address => mapping (uint256 => bytes))) public oracleProposed;
  mapping (address => mapping (address => mapping (uint256 => bool))) public oracleAccepted;
  mapping (address => mapping (address => mapping (uint256 => address))) public oracleDeployed;

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
    require(oracleDeployed[maker][taker][oracleIndex] == address(0));
    oracle = CentralizedBugOracle(new CentralizedBugOracleProxy(oracleMasterCopy, owner, _ipfsHash, maker, taker));
    oracleDeployed[maker][taker][oracleIndex] = oracle;
    emit OracleDeployed(maker, taker, oracleIndex, _ipfsHash, oracle);
  }

  //POTENTIAL VULNERABILITY IN UNKONWING MAKER
  function confirmOracle(address maker, uint index) public returns(bool) {
    require(oracleProposed[maker][msg.sender][index].length > 0);
    require(!oracleAccepted[maker][msg.sender][index]);

    if(balanceChecked[msg.sender]) checkBalance(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(fee);
    oracleAccepted[maker][msg.sender][index] = true;
    oracleIndexes[maker][msg.sender] += 1;

    emit OracleAccepted(maker, msg.sender, index, oracleProposed[maker][msg.sender][index]);
  }

  function buyOracle(bytes _ipfsHash, address taker) public whenOpen returns (uint index){
    if(balanceChecked[msg.sender]) checkBalance(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(fee);
    index = oracleIndexes[msg.sender][taker];
    oracleProposed[msg.sender][taker][index] = _ipfsHash;
    emit OracleProposed(msg.sender, taker, index, _ipfsHash);
  }

  function buyOracleFor(bytes _ipfsHash, address maker, address taker) public whenOpen isOwner{
    if(balanceChecked[maker]) checkBalance(maker);
    if(balanceChecked[taker]) checkBalance(taker);

    balances[maker] = balances[maker].sub(fee);
    balances[taker] = balances[taker].sub(fee);

    oracleProposed[maker][taker][oracleIndexes[maker][taker]] = _ipfsHash;
    oracleAccepted[maker][taker][oracleIndexes[maker][taker]] = true;
    address oracle = deployOracle(_ipfsHash,maker,taker,oracleIndexes[maker][taker]);
    oracleDeployed[maker][taker][oracleIndexes[maker][taker]] = oracle;
    oracleIndexes[maker][taker] += 1;
  }

  function revokeOracle(address taker, uint256 index) public {
    require(oracleProposed[msg.sender][taker][index].length >  0);
    require(!oracleAccepted[msg.sender][taker][index]);
    bytes memory hash = oracleProposed[msg.sender][taker][index];
    oracleProposed[msg.sender][taker][index] = "";
    balances[msg.sender] = balances[msg.sender].add(fee);
    emit OracleRevoked(msg.sender, taker, index, hash);
  }

  function checkBalance(address holder) public {
    require(!balanceChecked[holder]);
    balances[holder] = paymentToken.balanceOf(holder);
    balanceChecked[holder] = true;
  }

}
