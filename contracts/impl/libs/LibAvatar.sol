// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibAppStorage, AppStorage, Avatar } from "../../storage/LibAppStorage.sol";
import { LibConstant } from "./LibConstant.sol";

/**
 * common function library for Avatar
 */
library LibAvatar {

    /**
     * Mint a new NORMAL Avatar
     * @dev             will NOT check the validity of parameters. It should be guaranteed on Facet Layer 
     * @param _to       owner of the minted Avatar
     * @param _tokenId  id of the minted Avatar 
     */
    function mint(address _to, uint256 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // init a new Avatar
        Avatar storage avatar = s.avatars[_tokenId];
        avatar.owner = _to;
        avatar.mintTime = uint128(block.timestamp);
        avatar.status = LibConstant.STATUS_VRF_PENDING;

        // expand owner's collection
        s.avatarCollection[_to].push(_tokenId);
        // init _tokenId's index in owner's collection
        
    }
}