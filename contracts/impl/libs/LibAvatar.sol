// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibAppStorage, AppStorage, Avatar, RequestStatus } from "../../storage/LibAppStorage.sol";
import { LibConstant } from "./LibConstant.sol";
import { LibERC721 } from "../../shared/libraries/LibERC721.sol";

/**
 * common function library for Avatar
 */
library LibAvatar {

    event AvatarRendered(address indexed owner, uint256 indexed tokenId, uint256 indexed requestId);

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
        avatar.mintTime = uint64(block.timestamp);
        avatar.status = LibConstant.STATUS_VRF_PENDING;

        // expand owner's collection
        s.avatarCollection[_to].push(_tokenId);

        emit LibERC721.Transfer(address(0), _to, _tokenId);
    }

    /**
     * Render this Avatar's born attributes
     * 
     * @dev For now, Avatar's rendering only depends on randomWords in the following features:
     * 1. type of Avatar - currently they have the same rarities(mod by 12)
     * 
     * @param requestId     id of current VRF request
     * @param randomWords   random word generation result   
     */
    function renderAvatar(uint256 requestId, uint256[] memory randomWords) internal {
        require(randomWords.length >= 1, "LibAvatar: insufficient randomWords length");

        AppStorage storage s = LibAppStorage.diamondStorage();

        RequestStatus storage requestStatus = s.s_requests[requestId];

        require(requestStatus.exists, "LibAvatar: requestId not exists");
        require(!requestStatus.fulfilled, 'LibAvatar: request record alread fulfilled!');

        uint256 _tokenId = requestStatus.tokenId;

        s.avatars[_tokenId].randomNumber = randomWords[0];
        s.avatars[_tokenId].avatarType = uint16(randomWords[0] % LibConstant.AVATAR_TYPE_NUM + 1);
        // Rank - Initially Egg(1)
        s.avatars[_tokenId].rank = LibConstant.AVATAR_RANK_EGG;
        
        // render initial numerical values - start
        s.avatars[_tokenId].chronosis = 50;
        s.avatars[_tokenId].echo = 50;
        s.avatars[_tokenId].convergence = 50;
        // render initial numerical values - end

        // last update time init, start to decay
        s.avatars[_tokenId].lastUpdateTime = uint64(block.timestamp);
        
        s.avatars[_tokenId].status = LibConstant.STATUS_RUNNING;

        emit AvatarRendered(s.avatars[_tokenId].owner, _tokenId, requestId);
    }
}