// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { OperatorInterface } from "@chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { LibChainlinkProtocol } from "../shared/libraries/LibChainlinkProtocol.sol";

uint256 constant BOOST_SLOT_NUM = 32;

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

struct Avatar {

    /** owner of this object */
    address owner;

    /** current status 1=running, 2=VRF Rending, 3=invalid */
    uint8 status;

    /** type of this avatar */
    uint16 avatarType;

    /** 
     * rank of this avatar
     * 1 - Egg
     * 2 - Seed
     * 3 - Spirit
     * 4 - Doppelganger 
     */
    uint8 rank;

    /** time of this Avatar generated */
    uint64 mintTime;

    /** random number generated from chainlink VRF */
    uint256 randomNumber;

    /** last update time of the following SNAPSHOT metadata */
    uint64 lastUpdateTime;

    /**************************************************************************** 
     *= Snapshot Metadata Start ================================================*
     *= NOTE: value of these metadatas are SNAPSHOT taken at last update time. =*
     *======= These values are really updated when users have some actions =====*
     *======= affecting these metadata. i.e: Do a divination ===================*
     ****************************************************************************/
    /**
     * chronosis of this Avatar, represented by time interval between now and last interaction timestamp 
     */
    uint32 chronosis;

    /**
     * Echo of this Avatar, denoted as percentage(%)
     */
    uint32 echo;

    /**
     * Coverage of this Avatar, denoted as percentage(%)
     */
    uint32 convergence;

    /**
     * boost slots - starts from 1st
     * 1 - boosted by weather condition
     */
    uint16[BOOST_SLOT_NUM] boostSlots;

    /**
     * boost timestamp recorder
     */
    uint64[BOOST_SLOT_NUM] boostTimeRecorder;

    /****************************************************************************
     *= Snapshot Metadata End ==================================================*
     ****************************************************************************/

}

/****************************************************** 
 ***** other assistant objects definition starts ******
 ******************************************************/

/**
 * chianlink VRF request status recorder
 */
struct RequestStatus {
    bool fulfilled; // whether the request has been successfully fulfilled
    bool exists; // whether a requestId exists
    uint8 scene; // Usage for this requestId: 0-mainNFT; 1-fortuneCookie
    uint256 tokenId; // request random number result used for certain tokenId
    uint256[] randomWords;
}

struct PendingAPIRequest {
    address oracleAddress; // oracle address
    uint256 tokenId; // tokenId record
}


/****************************************************** 
 ******* other assistant objects definition ends ******
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

    /** address of diamond contract */
    address diamondAddress;

    /** Counter for minted normal Avatars */
    uint256 avatarCounter;

    /** Counter for minted legendary Avatars */
    uint256 legendaryAvatarCounter;

    /** tokenId -> Avatar */
    mapping(uint256 => Avatar) avatars;

    /** address -> tokenId list */
    mapping(address => uint256[]) avatarCollection;


    /****************************************************************************
     *= System configs start ===================================================*
     ****************************************************************************/

    /** Avatar mint started switch */
    bool avatarStarted;
    
    /************** chainlink configs start ***************/

    /** chainlink config initialized */
    bool chainlinkInit;

    mapping(uint256 => RequestStatus) s_requests; /* requestId --> requestStatus */

    /** Version2 VRF coordinator */
    VRFCoordinatorV2Interface COORDINATOR;

    /** VRF subscription ID. */
    uint64 s_subscriptionId;

    /** VRF Coordinator address - it varies from different blockchain network */
    address vrfCoordinator;

    /** VRF keyhash - it varies from different blockchain network */
    bytes32 keyHash;

    

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations;

    // number of rundom number retrieved from chainlink
    uint32 numWords;

    // oracle operator address
    OperatorInterface s_oracle;

    // LINK token contract address
    LinkTokenInterface s_link;

    /** 
     * chainlink jobId 
     * polygon mumbai - GET uint256: ca98366cc7314957b8c012c72f05aeeb
     */
    bytes32 jobId;

    // oracle request counter
    uint256 s_requestCount;

    // pending requests mapping 
    mapping(bytes32 => PendingAPIRequest) s_pendingRequests;

    // accuWeather API
    string accuWeatherApiKey;

    // chainlink's last request URL - used for test only
    string lastRequestURL;

    // chainlink's last request - used for test only
    string weather;

    // weather icon recorder
    uint8 weatherIcon;

    // request fee for each outside api request
    uint256 chainlinkRequestFee;

    // weather text mapping recorder
    mapping(bytes32 => uint8) weatherMapping;

    /************** chainlink configs end ********************/

    /****************************************************************************
     *= System configs end ===================================================*
     ****************************************************************************/
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

    /**
     * @dev Reverts if the sender is not the oracle of the request.
     * Emits ChainlinkFulfilled event.
     * @param requestId The request ID for fulfillment
     */
    modifier recordChainlinkFulfillment(bytes32 requestId) {
        require(msg.sender == s.s_pendingRequests[requestId].oracleAddress, "Source must be the oracle of the request");
        emit LibChainlinkProtocol.ChainlinkFulfilled(requestId);
        _;
    }

    // TODO: define other function decorations here
}