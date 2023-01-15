// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Modifiers } from '../../storage/LibAppStorage.sol';
import { LibRandomWord } from '../libs/LibRandomWord.sol';

contract VRFFacet is Modifiers {
    
    /***********************
     **** READ FUNCTIONS *** 
     ***********************/

    /**
     * query VRF subscription configs
     */
    function getVRFSubscriptionConfig() public view returns (uint64 s_subscriptionId, 
                                    address vrfCoordinator, 
                                    bytes32 keyHash,
                                    uint32 callbackGasLimit, 
                                    uint16 requestConfirmations,
                                    uint32 numWords) {
        s_subscriptionId = s.s_subscriptionId;
        vrfCoordinator = s.vrfCoordinator;
        keyHash = s.keyHash;
        callbackGasLimit = s.callbackGasLimit;
        requestConfirmations = s.requestConfirmations;
        numWords = s.numWords;
    }

    /***********************
     *** WRITE FUNCTIONS *** 
     ***********************/

    /**
     * callback function from Chainlink VRF when random words request is fulfilled
     * 
     * @dev     should check if the requestId exists & in pending state when the callback comes in
     * @param   requestId   random word requestId to chainlink VRF
     * @param   randomWords the generated random words
     */
    function rawFulfillRandomWords(uint256 requestId, 
			uint256[] memory randomWords) external {
        LibRandomWord.processRandomWord(requestId, randomWords);
    }

    /**
     * switch the status of VRF subscription
     *
     * @dev only owner of this contract can execute
     */
    function vrfSwitch() external onlyOwner {
        s.chainlinkInit = !s.chainlinkInit;
    }
}