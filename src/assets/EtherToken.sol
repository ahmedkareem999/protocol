pragma solidity ^0.4.11;

import "ds-weth/eth_wrapper.sol";

/// @title EtherToken Contract.
/// @author Melonport AG <team@melonport.com>
contract EtherToken is DSEthToken {

    // Constant fields
    string public constant name = "Ether Token";
    string public constant symbol = "ETH-T";
    uint public constant decimals = 18;
}
