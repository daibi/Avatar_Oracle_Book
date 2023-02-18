// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Modifiers, Avatar } from '../storage/LibAppStorage.sol';
import { LibConstant } from '../impl/libs/LibConstant.sol';


/**
 * This contract is only used for mocking test cases ONLY!
 * DO NOT deploy this contract on real environment
 */
contract AvatarInitializeFacet is Modifiers {

    /**
     * mock new avatar NFT
     */
    function mockAvatar(address _to, uint32 chronosis, uint32 echo, uint32 convergence, uint256 lastUpdateTime, uint16 avatarType, uint8 rank) external {
        require(_to != address(0), "AvatarFacet: mint to zero address!");

        uint256 tokenId = LibConstant.NORMAL_AVATAR_START_ID + s.avatarCounter;

        Avatar storage avatar = s.avatars[tokenId];

        avatar.owner = _to;
        avatar.mintTime = uint64(lastUpdateTime);
        avatar.lastUpdateTime = uint64(lastUpdateTime);
        avatar.status = LibConstant.STATUS_RUNNING;
        avatar.chronosis = chronosis;
        avatar.echo = echo;
        avatar.convergence = convergence;
        avatar.avatarType = avatarType;
        avatar.rank = rank;

        // increase the normal Avatar Counter
        unchecked {
            s.avatarCounter++;
        }
    }
}