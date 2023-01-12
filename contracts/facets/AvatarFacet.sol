// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Modifiers } from '../storage/LibAppStorage.sol';
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { LibConstant } from '../libraries/avatar/LibConstant.sol';
import { LibAvatar } from '../libraries/avatar/LibAvatar.sol';

/**
 * main NFT character - Avatar Facet
 */
contract AvatarFacet is Modifiers {

    /***********************
     **** READ FUNCTIONS *** 
     ***********************/

    
    /***********************
     *** WRITE FUNCTIONS *** 
     ***********************/
    function whitelistMint() public payable {

    }

    /**
     * mint a new Avatar
     * @dev         mint to address 0x0 is invalid
     * @dev         mint process started from tokenId 101, since the former 1-100 are of legendary Avatars
     * @dev         tokenId of Avatar should never be greater than 999
     * @param _to   the owner of newly minted Avatar
     */
    function mint(address _to) external payable {
        require(_to != address(0), "AvatarFacet: mint to zero address!");
        require(s.avatarStarted, "AvatarFacet: avatar mint is not started!");

        uint256 currentTokenId = Counters.current(s.avatarCounter);
        require(currentTokenId <= LibConstant.MAX_AVATAR_ID, "AvatarFacet: out of Avatars!");

        LibAvatar.mint(_to, currentTokenId);

        // increase the normal Avatar Counter
        Counters.increment(s.avatarCounter);
    }

}