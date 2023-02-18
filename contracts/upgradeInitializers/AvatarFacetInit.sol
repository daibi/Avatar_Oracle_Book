// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibAppStorage, AppStorage } from '../storage/LibAppStorage.sol';

contract AvatarFacetInit {

    /**
     * init setup for Avatar Facet plugin
     * @dev should init the avatar counters to 1
     */
    function init() public {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // init the Counters to 1
        unchecked {
            s.avatarCounter++;
            s.legendaryAvatarCounter++;
        }
    }
}