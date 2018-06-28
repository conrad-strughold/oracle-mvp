pragma solidity ^0.4.24;
//import "../Oracles/Oracle.sol";
import "../Oracles/CentralizedOracle.sol";
import "../Utils/Proxy.sol";
import "../Tokens/Token.sol";


contract OracleVendingMachineInterface {

    function buyOracle(bytes _ipfsHash) public returns (Oracle oracle);
    function upgrade(address _masterCopy) public;
    function changeFee(uint _fee) public;
    function upgradeOracle(address _oracleMasterCopy) public;
    function changeToken(address _token) public;

}

contract OracleVendingMachineData {

    /*
     *  Events
     */
    event OracleCreation(address indexed creator, Oracle centralizedOracle, bytes ipfsHash);

    /*
     *  Storage
     */
    address public owner;
    uint public fee;
    address public oracleMasterCopy;
    Token public paymentToken;

    /*
     *  Modifiers
     */
    modifier isOwner () {
        // Only owner is allowed to proceed
        require(msg.sender == owner);
        _;
    }

    /*
     *  Basic permanent functions
     */
    function upgrade(address _masterCopy) public isOwner {
        masterCopy = _masterCopy;
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
}

contract OracleVendingMachine is Proxied, OracleVendingMachineData {
    /// @dev Constructor sets owner address and IPFS hash
    /// @param _ipfsHash Hash identifying off chain event description
    constructor(address proxied, address _owner, Token _paymentToken, bytes _fee, address _oracleMasterCopy)
        public
        Proxy(proxied)
    {
        owner = _owner;
        fee = _fee;
        oracleMasterCopy = _oracleMasterCopy;
        paymentToken = _paymentToken;
    }
}

contract OracleVendingMachineProxy is Proxy, OracleVendingMachineInterface, OracleVendingMachineData {

    function buyOracle(bytes _ipfsHash) public returns (Oracle oracle){
        require(token.transferFrom(msg.sender, owner, fee));
        oracle = CentralizedOracle(new CentralizedOracleProxy(oracleMasterCopy, owner, _ipfsHash));
        emit OracleCreation(msg.sender, oracle, _ipfsHash);
    }

}