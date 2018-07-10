pragma solidity ^0.4.24;

import "./Oracle.sol";
import "./Proxy.sol";

contract CentralizedBugOracleData {
  event OwnerReplacement(address indexed newOwner);
  event OutcomeAssignment(int outcome);

  /*
   *  Storage
   */
  address public owner;
  bytes public ipfsHash;
  bool public isSet;
  int public outcome;
  address public maker;
  address public taker;

  /*
   *  Modifiers
   */
  modifier isOwner () {
      // Only owner is allowed to proceed
      require(msg.sender == owner);
      _;
  }
}

contract CentralizedBugOracleProxy is Proxy, CentralizedBugOracleData {

    /// @dev Constructor sets owner address and IPFS hash
    /// @param _ipfsHash Hash identifying off chain event description
    constructor(address proxied, address _owner, bytes _ipfsHash, address _maker, address _taker)
        public
        Proxy(proxied)
    {
        // Description hash cannot be null
        require(_ipfsHash.length == 46);
        owner = _owner;
        ipfsHash = _ipfsHash;
        maker = _maker;
        taker = _taker;
    }
}

contract CentralizedBugOracle is Proxied,Oracle, CentralizedBugOracleData{

  /// @dev Sets event outcome
  /// @param _outcome Event outcome
  function setOutcome(int _outcome)
      public
      isOwner
  {
      // Result is not set yet
      require(!isSet);
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


  //@dev internal funcion to set the outcome sat
  function _setOutcome(int _outcome) internal {
    isSet = true;
    outcome = _outcome;
    emit OutcomeAssignment(_outcome);
  }


}
