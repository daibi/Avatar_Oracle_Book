// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibAppStorage, AppStorage, Avatar, RequestStatus } from "../../storage/LibAppStorage.sol";
import { LibAvatar } from "./LibAvatar.sol";
import { LibConstant } from "./LibConstant.sol";

/**
 * library for random words processing
 */
library LibRandomWord {

    /**
     * process the random word received, will route into the execute via the recorded RequestStatus
     * @dev should revert when request doesn't exist or has already been fulfilled
     * 
     * @param requestId     request id for requesting chainlink VRF
     * @param randomWords   random word generation result
     */
    function processRandomWord(uint256 requestId, uint256[] memory randomWords) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        // 1. retrieve RequestStatus from s_requests record
        RequestStatus storage requestStatus = s.s_requests[requestId];

        require(requestStatus.exists, 'LibRandomWord: request record not exist!');
        require(!requestStatus.fulfilled, 'LibRandomWord: request record alread fulfilled!');

        // 2. route into execute function via <scene>
        if (requestStatus.scene == LibConstant.REQUEST_SCENE_AVATAR_RENDER) {
            LibAvatar.renderAvatar(requestId, randomWords);
        }

        // 3. update random word request status to fulfilled
        requestStatus.fulfilled = true;
    }   
}