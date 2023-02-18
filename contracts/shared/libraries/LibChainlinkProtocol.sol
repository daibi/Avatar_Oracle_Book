// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library LibChainlinkProtocol {
    
    event ChainlinkRequested(bytes32 indexed id);
    
    event ChainlinkFulfilled(bytes32 indexed id);
    
    event ChainlinkCancelled(bytes32 indexed id);
}