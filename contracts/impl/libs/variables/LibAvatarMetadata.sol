// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { AppStorage, LibAppStorage, Avatar } from '../../../storage/LibAppStorage.sol';
import { Math } from  "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { LibChronosis } from './LibChronosis.sol';
import { LibEcho } from './LibEcho.sol';
import { LibConvergence } from './LibConvergence.sol';

import { toWadUnsafe } from "../common/SignedWadMath.sol";

import "hardhat/console.sol";

/**
 * common structure used for all metadata calculation
 */
struct MetadataCalcParams {

    /************ metadata snapshot value starts  **************/
    uint32 chronosis;
    uint32 echo;
    uint32 convergence;
    /************* metadata snapshot value ends  ***************/


    /************ decay rate values starts  **************/
    uint16 coefficient;
    uint16 echoDecayRate;
    uint16 convergenceDecayRate;
    /************* decay rate values ends  ***************/

    /************** common condition values starts *************/
    bool exponential;
    uint64 lastUpdateTime;
    uint64 currentTime;
    uint64 nextThresholdTimestamp;
    /*************** common condition values ends **************/

}

/**
 * struct used for updated values
 */
struct UpdateValues {

    uint32 chronosis;

    uint32 echo;

    uint32 convergence;
}

/**
 * library used for Avatar's metadata calculation
 */
library LibAvatarMetadata {

    function currentMetadata(uint256 _tokenId) internal view 
        returns(
            uint32 newChronosis, 
            uint32 newEcho, 
            uint32 newConvergence
        ) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.avatars[_tokenId].status > 0, 'LibAvatarMetadata: invalid token id');

        uint64 currentTime = uint64(block.timestamp);

        uint64 lastUpdateTime = s.avatars[_tokenId].lastUpdateTime;
        uint8 rank = s.avatars[_tokenId].rank; 

        // BE AWARE: these are snapshot value!
        uint32 chronosis = s.avatars[_tokenId].chronosis;
        uint32 echo = s.avatars[_tokenId].echo; 
        uint32 convergence = s.avatars[_tokenId].convergence;

        // based on last snapshot chronosis value & rank, get current chronosis decay rate
        (uint16 coefficient, bool exponential) = LibChronosis.getBaseDecayRate(rank, chronosis);

        // coeffcient should get waded since it may involve decimal calculation
        uint256 coefficientWad = toWadUnsafe(coefficient);
        console.log("Current Chronosis value: %d, base decay rate: %d, exponential config: %s", chronosis, coefficientWad, exponential);
            
        /****** Decay rate coefficient effect calculation starts *********/
        // based on last snapshot echo, convergence, etc..., calculate current final decay rate of chronsis affected by these metadatas
        // 1. affected by current echo value
        coefficientWad = LibEcho.getAffectedDecayRate(rank, echo, coefficient, exponential);
        // 2. affected by current convergence value
        coefficientWad = LibConvergence.getAffectedDecayRate(rank, convergence, coefficientWad, exponential);

        console.log("coefficient after other metadata's effect: %d", coefficientWad);
        /******** Decay rate coefficient effect calculation ends *********/

        /********** Correlated decay rate for other metadatas starts *********/
        // 1. correlated decay rate for Echo
        uint16 echoDecayRate = LibEcho.getCorrelateDecayRate(coefficient);
        // 2. correlated decay rate for Convergence
        uint16 convergenceDecayRate = LibConvergence.getCorrelateDecayRate(coefficient);
        /*********** Correlated decay rate for other metadatas ends **********/

        // init calculation param structure
        MetadataCalcParams memory calcParams = MetadataCalcParams({
            chronosis: chronosis, 
            echo: echo,
            convergence: convergence,
            coefficient: coefficient,
            echoDecayRate: echoDecayRate,
            convergenceDecayRate: convergenceDecayRate,
            exponential: exponential,
            lastUpdateTime: lastUpdateTime,
            currentTime: currentTime,
            nextThresholdTimestamp: currentTime
        });

        // during each loop, calculate the nearest metadata's threshold that is before current timestamp
        uint256 nextThresholdTimestamp = currentTime;
        UpdateValues memory updateValues;
        do {
            // record timestamp result
            calcParams.nextThresholdTimestamp = uint64(getNextThresholdTimestamp(calcParams));

            // batch update metadata value
            updateValues = batchUpdate(calcParams);
            
            /*********** Next loop Starts **********/
        } while (calcParams.nextThresholdTimestamp < currentTime);
    }

    /**
     * calculate the nearest timestamp for values' reaching their next threshold value
     * 
     * @param   calcParams      calculate input params
     * @return  result          next timestamp for reaching threshold
     */
    function getNextThresholdTimestamp(MetadataCalcParams memory calcParams) internal pure returns (uint256) {
        uint256 nextThresholdTimestamp = uint256(calcParams.currentTime);
        // chronosis
        nextThresholdTimestamp = Math.min(nextThresholdTimestamp,
                LibChronosis.getNextThresholdTimestamp(calcParams.chronosis, calcParams.coefficient, calcParams.exponential, calcParams.lastUpdateTime, calcParams.currentTime));

        // echo
        nextThresholdTimestamp = Math.min(nextThresholdTimestamp, 
                LibEcho.getNextThresholdTimestamp(calcParams.echo, calcParams.echoDecayRate, calcParams.exponential, calcParams.lastUpdateTime, calcParams.currentTime));
            
        // convergence
        nextThresholdTimestamp = Math.min(nextThresholdTimestamp, 
                LibConvergence.getNextThresholdTimestamp(calcParams.convergence, calcParams.convergenceDecayRate, calcParams.exponential, calcParams.lastUpdateTime, calcParams.currentTime));

        return uint64(nextThresholdTimestamp);
    }

    /**
     * batch update metadata
     * @dev will add more update metadata in the future
     * 
     * @param   calcParams      calculate input params
     * @return  updateValues    updated metadata value
     */
    function batchUpdate(MetadataCalcParams memory calcParams) internal pure returns (
            UpdateValues memory updateValues
    ) {
        // for the nearest elapsed time for one of the metadatas' coming to its threshold, calculate other metadata's value at that moment
        // chronosis
        updateValues.chronosis = update(calcParams.lastUpdateTime, calcParams.nextThresholdTimestamp, calcParams.chronosis, calcParams.coefficient, calcParams.exponential);
            
        // echo
        updateValues.echo = update(calcParams.lastUpdateTime, calcParams.nextThresholdTimestamp, calcParams.echo, calcParams.echoDecayRate, calcParams.exponential);

        // convergence
        updateValues.convergence = update(calcParams.lastUpdateTime, calcParams.nextThresholdTimestamp, calcParams.convergence, calcParams.convergenceDecayRate, calcParams.exponential);
    }

    /**
     * update metadata
     *
     * @param   from              from timestamp
     * @param   to                to timestamp
     * @param   snapshot          snapshot value
     * @param   decayRate         decay rate
     * @param   exponential       if it is in the exponentially decaying mode
     * 
     * @return  currentValue      updated value
     */
    function update(uint64 from, uint64 to, uint32 snapshot, uint16 decayRate, bool exponential) internal pure returns(uint32 currentValue) {
        // 1. calculate elapsed minute from <from> to <to>
        uint256 elapsedMinute = Math.mulDiv(SafeMath.sub(to, from), 1, 60 * 1000, Math.Rounding.Down);

        // 2. given current decay rate, exponential config, calculate updated value
        currentValue = exponential ? uint32(snapshot - decayRate * elapsedMinute * elapsedMinute) :
            uint32(snapshot - decayRate * elapsedMinute);

    }
}
