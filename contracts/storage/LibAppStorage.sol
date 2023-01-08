// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

/* 
 * Storage Slot Defination In a Human Readable Format
 * For an upgradable smart contract, 
 *  it is never TOO cautious on the storage slot distribution
 * This implementation follows the 'AppStorage Pattern' to come up with a more humanreadable storage allocation
 * For detailed information, please refer to 
 * https://eip2535diamonds.substack.com/p/appstorage-pattern-for-state-variables?s=w
 * 
 * For every NEWLY introduced storage, developers should design the storage pattern in AppStorage to have a better accessing performance.
*/ 

/**
 * TODO define the name of the main object for this project
 */
struct Avatar {

    /** owner of this object */
    address owner;

    /********************************************** 
     ******* TODO some other metadata start *******
     **********************************************/

    // TODO make metadata definitions here

    /** type of this avatar */
    uint256 avatarType;

    /** 
     * rank of this avatar
     * 1 - Egg
     * 2 - Seed
     * 3 - Spirit
     * 4 - Doppelganger 
     */
    uint8 rank;

    /**
     * time limited boosts(features) array
     * 0 - 
     */


    /**
     * TimeDecay of this Avatar, represented by time interval between now and last interaction timestamp 
     */
    uint256 timeDecay;

    /**
     * Echo of this Avatar, denoted as percentage(%)
     */
    uint256 echo;


    /********************************************** 
     ******** TODO some other metadata ends *******
     **********************************************/

}

/****************************************************** 
 *** TODO other assistant objects definition starts ***
 ******************************************************/

// TODO make other assistant definitions here

/****************************************************** 
 **** TODO other assistant objects definition ends ****
 ******************************************************/

/**
 * TODO (If needed), the defination of chainlink request
 */
struct ChainlinkRequestStatus {
        
    /** whether the request has been successfully fulfilled */
    bool fulfilled; 

    /** whether a requestId exists */
    bool exists; 

    /** 
     * TODO: define the type of chainlink request result
     * which can be uint256, string etc...
     */
    uint256 randomNumber;
}

/**
 * Common storage for diamond project
 */
struct AppStorage {

    // TODO: define the recorder of project's main object

    /** Counter for mainCharacterCounter */
    Counters.Counter mainCharacterCounter;

    mapping(uint256 => SomeMainCharacter) someMainCharacters;


    // TODO define other storage settings here
}

/**
 * AppStorage pattern library, this will ensure every facet will interact with the RIGHT storage address inside the diamond contract
 * For detailed information, please refer to: https://eip2535diamonds.substack.com/p/appstorage-pattern-for-state-variables?s=w
 */
library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

/**
 * A base contract with common AppStorage defined that can prevent storage collisions,
 * with some decoration common usage defined
 */
contract Modifiers {

    AppStorage internal s;

    /**
     * Decoration: should check if the msg.sender is the contract owner
     */
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    // TODO: define other function decorations here
}