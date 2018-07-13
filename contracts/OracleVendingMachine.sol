pragma solidity ^0.4.24;

import "./Oracle.sol";
import "./Proxy.sol";
import "./SafeMath.sol";
import "./Token.sol";
import "./CentralizedBugOracle.sol";

//Vending machine Logic goes in this contract
contract OracleVendingMachine {
  using SafeMath for *;

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
  Oracle public oracleMasterCopy;
  Token public paymentToken;
  bool public open;


  mapping (address => uint256) public balances;
  mapping (address => bool) public balanceChecked;
  mapping (address => mapping (address => uint256)) public oracleIndexes;
  mapping (address => mapping (address => mapping (uint256 => bytes))) public oracleProposed;
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
    //Only proceeds with operation if open is true
    require(open);
    _;
  }

  /**
    @dev Contructor to the vending Machine
    @param _fee The for using the vending Machine
    @param _token the Address of the token used for paymentToken
    @param _oracleMasterCopy The deployed version of the oracle which will be proxied to
  **/
  constructor(uint _fee, address _token, address _oracleMasterCopy) public {
    owner = msg.sender;
    fee = _fee;
    paymentToken = Token(_token);
    oracleMasterCopy = Oracle(_oracleMasterCopy);
    open = true;
  }

  /**
    @dev Change the fee
    @param _fee Te new vending machine fee
  **/
  function changeFee(uint _fee) public isOwner {
      fee = _fee;
  }

  /**
    @dev Change the master copy of the oracle
    @param _oracleMasterCopy The address of the deployed version of the oracle which will be proxied to
  **/
  function upgradeOracle(address _oracleMasterCopy) public isOwner {
      oracleMasterCopy = Oracle(_oracleMasterCopy);
  }

  /**
    @dev Change the payment token
    @param _paymentToken the Address of the token used for paymentToken
  **/
  function changePaymentToken(address _paymentToken) public isOwner {
      paymentToken = Token(_paymentToken);
  }

  /**
    @dev Contructor to the vending Machine
    @param status The new open status for the vending Machine
  **/
  function modifyOpenStatus(bool status) public isOwner {
    open = status;
  }


  /**
    @dev Internal function to deploy and register a oracle
    @param _ipfsHash The hash for the bug information(description, spurce code, etc)
    @param maker the Address who proposed the oracle
    @param taker the Address who accepted the oracle
    @param index The index of the oracle to be deployed
    @return A deployed oracle contract
  **/
  function deployOracle(bytes _ipfsHash, address maker, address taker, uint256 index) internal returns(Oracle oracle){
    require(oracleDeployed[maker][taker][index] == address(0));
    oracle = CentralizedBugOracle(new CentralizedBugOracleProxy(oracleMasterCopy, owner, _ipfsHash, maker, taker));
    oracleDeployed[maker][taker][index] = oracle;
    emit OracleDeployed(maker, taker, index, _ipfsHash, oracle);
  }


  /**
    @dev Function called by he taker to confirm a proposed oracle
    @param maker the Address who proposed the oracle
    @param index The index of the oracle to be deployed
    @return A deployed oracle contract
  **/
  function confirmOracle(address maker, uint index) public returns(Oracle oracle) {
    require(oracleProposed[maker][msg.sender][index].length > 0);

    if(!balanceChecked[msg.sender]) checkBalance(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(fee);

    oracle = deployOracle(oracleProposed[maker][msg.sender][index], maker, msg.sender, index);
    oracleIndexes[maker][msg.sender] += 1;
    emit OracleAccepted(maker, msg.sender, index, oracleProposed[maker][msg.sender][index]);
  }


  /**
    @dev Function to propose an oracle, calle by maker
    @param _ipfsHash The hash for the bug information(description, spurce code, etc)
    @param taker the Address who needs to accept the oracle
    @return index of the proposal
  **/
  function buyOracle(bytes _ipfsHash, address taker) public whenOpen returns (uint index){
    if(!balanceChecked[msg.sender]) checkBalance(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(fee);
    index = oracleIndexes[msg.sender][taker];
    oracleProposed[msg.sender][taker][index] = _ipfsHash;
    emit OracleProposed(msg.sender, taker, index, _ipfsHash);
  }

  /**
    @dev Priviledged function to propose and deploy an oracle with one transaction. Called by Solidified Bug Bounty plataform
    @param _ipfsHash The hash for the bug information(description, spurce code, etc)
    @param maker the Address who proposed the oracle
    @param taker the Address who accepted the oracle
    @return A deployed oracle contract
  **/
  function buyOracleFor(bytes _ipfsHash, address maker, address taker) public whenOpen isOwner returns(Oracle oracle){
    if(!balanceChecked[maker]) checkBalance(maker);
    if(!balanceChecked[taker]) checkBalance(taker);

    balances[maker] = balances[maker].sub(fee);
    balances[taker] = balances[taker].sub(fee);

    oracleProposed[maker][taker][oracleIndexes[maker][taker]] = _ipfsHash;
    oracle = deployOracle(_ipfsHash,maker,taker,oracleIndexes[maker][taker]);
    oracleDeployed[maker][taker][oracleIndexes[maker][taker]] = oracle;
    oracleIndexes[maker][taker] += 1;
  }

  /**
    @dev  Function to cancel a proposed oracle, called by the maker
    @param taker the Address who accepted the oracle
    @param index The index of the proposed to be revoked
  **/
  function revokeOracle(address taker, uint256 index) public {
    require(oracleProposed[msg.sender][taker][index].length >  0);
    require(oracleDeployed[msg.sender][taker][index] == address(0));
    bytes memory hash = oracleProposed[msg.sender][taker][index];
    oracleProposed[msg.sender][taker][index] = "";
    balances[msg.sender] = balances[msg.sender].add(fee);
    emit OracleRevoked(msg.sender, taker, index, hash);
  }

  /**
    @dev Function to check a users balance of SOLID and deposit as credit
    @param holder Address of the holder to be checked
  **/
  function checkBalance(address holder) public {
    require(!balanceChecked[holder]);
    balances[holder] = paymentToken.balanceOf(holder);
    balanceChecked[holder] = true;
  }

}
