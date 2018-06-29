pragma solidity ^0.4.24;

import "./Gnosis/Oracles/Oracle.sol";

contract CentralizedBugOracle is Oracle{

  /*
   *  Storage
   */
  address public owner;
  bytes public ipfsHash;
  bool public isSet;
  int public outcome;
  uint256 public fee;
  uint256 public fundingPeriod;
  address public maker;
  address public taker;
  bool public ready;

  mapping(address => uint256) funding;
  mapping(address => uint256) desiredOutcome;

  /*
   *  Modifiers
   */
  modifier isOwner () {
      // Only owner is allowed to proceed
      require(msg.sender == owner);
      _;
  }

  /// @dev Funds the contract with tokens to pay fo rrulling
  function fund(address _side, uint256 _amount){
    funding[_side] += amount;
  }

  /// Puts the contract in a state to give rulling
  function setReady(){
    require(funding[maker] >= fee);
    require(funding[taker] >= fee);
    ready = true;
  }

  //Gives a rulling in favor of maker  if taker doesn not fund the contract in appropriate time
  function walkoverRulling() {
    if(now > fundingPeriod){
      require(funding[maker] > fee);
      _setOutcome(desiredOutcome(maker));
    }
  }

  /// @dev Sets event outcome
  /// @param _outcome Event outcome
  function setOutcome(int _outcome)
      public
      isOwner
  {
      // Result is not set yet
      require(!isSet);
      require(ready);
      _setOutcome(_outcome);
  }

  /// @dev Returns if winning outcome is set
  /// @return Is outcome set?
  function isOutcomeSet()
      public
      view
      returns (bool)
  {
      return isSet;
  }

  /// @dev Returns outcome
  /// @return Outcome
  function getOutcome()
      public
      view
      returns (int)
  {
      return outcome;
  }


  //@dev internal funcion to set the outcome state
  function _setOutcome(int _outcome) internal {
    isSet = true;
    outcome = _outcome;
    emit OutcomeAssignment(_outcome);
  }


}
