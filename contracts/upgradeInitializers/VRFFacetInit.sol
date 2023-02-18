// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibAppStorage, AppStorage } from '../storage/LibAppStorage.sol';

contract VRFFacetInit {

    /**
     * init VRF subscriber configurations when VRFFacet is plugined in
     * @dev should determine the subscription config after the subscription registration on Chainlink
     * 
     * @param _vrfCoordinator       address of VRF coordinator in given blockchain environment
     * @param _subscriptionId       subscription id assigned when registration
     * @param _keyHash              keyhash in given blockchain environment
     * @param _callbackGasLimit     gas limit for randomWordFulfilled callback
     * @param _requestConfirmations number of confirmation needed for each generated random words
     * @param _numWords             number of random words generated at each random word request
     */
    function init(address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash, uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords) external {
        
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.vrfCoordinator = _vrfCoordinator;
        s.s_subscriptionId = _subscriptionId;
        s.keyHash = _keyHash;
        s.callbackGasLimit = _callbackGasLimit;
        s.requestConfirmations = _requestConfirmations;
        s.numWords = _numWords;
        s.chainlinkRequestFee = (1 * 10**18) / 10;
    }
}