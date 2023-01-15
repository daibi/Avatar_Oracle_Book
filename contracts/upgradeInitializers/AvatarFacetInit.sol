// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibAppStorage, AppStorage } from '../storage/LibAppStorage.sol';
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

contract AvatarFacetInit {

    /**
     * init setup for Avatar Facet plugin
     * @dev should init the avatar counters to 1
     */
    function init() public {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // init the Counters to 1
        Counters.increment(s.avatarCounter);
        Counters.increment(s.legendaryAvatarCounter);
    }
}