// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Modifiers, RequestStatus } from '../../storage/LibAppStorage.sol';
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { LibConstant } from '../libs/LibConstant.sol';
import { LibAvatar } from '../libs/LibAvatar.sol';
import { LibAvatarMetadata, UpdateValues } from '../libs/variables/LibAvatarMetadata.sol';
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * main NFT character - Avatar Facet
 */
contract AvatarFacet is Modifiers {

    /***********************
     **** READ FUNCTIONS *** 
     ***********************/

    function totalNormalAvatar() external view returns(
        uint256 count
    ) {
        count = Counters.current(s.avatarCounter) - 1;
    }

    /**
     * get token's detailed feature by _tokenId
     * @dev     should check if the token of _tokenId exists
     * 
     * @param _tokenId  token id 
     */
    function getByTokenId(uint256 _tokenId) external view returns(
        address owner,
        uint8 status,
        uint16 avatarType,
        uint8 rank,
        uint64 mintTime,
        uint256 randomNumber,
        uint64 lastUpdateTime,
        uint32 chronosis,
        uint32 echo,
        uint32 convergence
    ) {
        require(s.avatars[_tokenId].status > 0, "AvatarFacet: avatar not exist");

        owner = s.avatars[_tokenId].owner;
        status = s.avatars[_tokenId].status;
        avatarType = s.avatars[_tokenId].avatarType;
        mintTime = s.avatars[_tokenId].mintTime;

        // should render the following variables when status is STATUS_RUNNING
        if (status == LibConstant.STATUS_RUNNING) {
            rank = s.avatars[_tokenId].rank;
            randomNumber = s.avatars[_tokenId].randomNumber;
            lastUpdateTime = s.avatars[_tokenId].lastUpdateTime;
            UpdateValues memory updateValues = LibAvatarMetadata.currentMetadata(_tokenId);
            chronosis = updateValues.chronosis;
            echo = updateValues.echo;
            convergence = updateValues.convergence;
        }
    }

    /**
     * query the NFT balance of _owner
     * 
     * @dev if it is a new address, return 0 as result
     * @param _owner    user address
     */
    function balanceOf(address _owner) external view returns(uint256 balance){
        balance = s.avatarCollection[_owner].length;
    }
    
    /***********************
     *** WRITE FUNCTIONS *** 
     ***********************/

    /**
     * switch the Avatar's minting state
     */
    function mintSwitch() public onlyOwner {
        s.avatarStarted = !s.avatarStarted;
    }
    
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
        require(s.chainlinkInit, "AvatarFacet: chainlink is not initialized");

        uint256 _currentTokenId = LibConstant.NORMAL_AVATAR_START_ID + Counters.current(s.avatarCounter);
        require(_currentTokenId <= LibConstant.MAX_AVATAR_ID, "AvatarFacet: out of Avatars!");

        LibAvatar.mint(_to, _currentTokenId);

        // request VRF random number for avatar rendering
        requestRandomWord(_currentTokenId);

        // increase the normal Avatar Counter
        Counters.increment(s.avatarCounter);
    }

    /**
     * request random word from chainlink VRF Subscriber
     * 
     * @param _currentTokenId   current Avatar's tokenId    
     */
    function requestRandomWord(uint256 _currentTokenId) internal {
        uint256 requestId = VRFCoordinatorV2Interface(s.vrfCoordinator).requestRandomWords(
            s.keyHash,
            s.s_subscriptionId,
            s.requestConfirmations,
            s.callbackGasLimit,
            s.numWords
        );

        // record this request Id for the newly generated Avatar
        s.s_requests[requestId] = RequestStatus({
            exists: true,
            fulfilled: false,
            randomWords: new uint256[](0),
            tokenId: _currentTokenId,
            scene: LibConstant.REQUEST_SCENE_AVATAR_RENDER
        });
    } 

}