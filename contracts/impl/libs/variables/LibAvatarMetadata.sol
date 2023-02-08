// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { AppStorage, LibAppStorage, Avatar } from '../../../storage/LibAppStorage.sol';
import { Math } from  "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { LibChronosis } from './LibChronosis.sol';
import { LibEcho } from './LibEcho.sol';
import { LibConvergence } from './LibConvergence.sol';

import { toWadUnsafe, unWadUnsafe } from "../common/SignedWadMath.sol";



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
    uint256 coefficientWad;
    uint256 echoDecayRateWad;
    uint256 convergenceDecayRateWad;
    /************* decay rate values ends  ***************/

    /************** common condition values starts *************/
    bool exponential;
    uint64 lastUpdateTime;
    uint64 currentTime;
    uint64 nextThresholdTimestamp;
    uint8 rank;
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

    /**
     * calculate current metadata value given the decay effect for _tokenId
     * 
     * @param   _tokenId        token id 
     * @return  updateValues    updated snapshot values
     */
    function currentMetadata(uint256 _tokenId) internal view 
        returns(
            UpdateValues memory updateValues
        ) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.avatars[_tokenId].status > 0, 'LibAvatarMetadata: invalid token id');

        uint64 currentTime = uint64(block.timestamp);

        // init calculation param structure
        MetadataCalcParams memory calcParams = MetadataCalcParams({
            chronosis: s.avatars[_tokenId].chronosis, 
            echo: s.avatars[_tokenId].echo,
            convergence: s.avatars[_tokenId].convergence,
            coefficientWad: 0,
            echoDecayRateWad: 0,
            convergenceDecayRateWad: 0,
            exponential: false,
            lastUpdateTime: s.avatars[_tokenId].lastUpdateTime,
            currentTime: currentTime,
            nextThresholdTimestamp: currentTime,
            rank: s.avatars[_tokenId].rank
        });

        // during each loop, calculate the nearest metadata's threshold that is before current timestamp
        do {
            // based on last snapshot chronosis value & rank, get current chronosis decay rate
            (uint16 coefficient, bool exponential) = LibChronosis.getBaseDecayRate(calcParams.rank, calcParams.chronosis);

            // coeffcient should get waded since it may involve decimal calculation
            uint256 coefficientWad = toWadUnsafe(coefficient);
                
            /****** Decay rate coefficient effect calculation starts *********/
            // based on last snapshot echo, convergence, etc..., calculate current final decay rate of chronsis affected by these metadatas
            // 1. affected by current echo value
            coefficientWad = LibEcho.getAffectedDecayRate(calcParams.rank, calcParams.echo, coefficientWad, exponential);
            // 2. affected by current convergence value
            coefficientWad = LibConvergence.getAffectedDecayRate(calcParams.rank, calcParams.convergence, coefficientWad, exponential);
            /******** Decay rate coefficient effect calculation ends *********/

            /********** Correlated decay rate for other metadatas starts *********/
            // 1. correlated decay rate for Echo
            uint256 echoDecayRateWad = LibEcho.getCorrelateDecayRate(coefficientWad);
            // 2. correlated decay rate for Convergence
            uint256 convergenceDecayRateWad = LibConvergence.getCorrelateDecayRate(coefficientWad);
            /*********** Correlated decay rate for other metadatas ends **********/

            // update coeffcients value in calcParams
            calcParams.coefficientWad = coefficientWad;
            calcParams.echoDecayRateWad = echoDecayRateWad;
            calcParams.convergenceDecayRateWad = convergenceDecayRateWad;
            calcParams.exponential = exponential;

            // record timestamp result
            calcParams.nextThresholdTimestamp = uint64(getNextThresholdTimestamp(calcParams));

            // batch update metadata value
            updateValues = batchUpdate(calcParams);

            // update values inside calcParams
            calcParams.lastUpdateTime = calcParams.nextThresholdTimestamp;
            calcParams.chronosis = updateValues.chronosis;
            calcParams.echo = updateValues.echo;
            calcParams.convergence = updateValues.convergence;
            
            /*********** Next loop Starts **********/
        } while (calcParams.nextThresholdTimestamp < currentTime && !hasZero(calcParams)); 
    }

    /**
     * calculate the nearest timestamp for values' reaching their next threshold value
     * 
     * @param   calcParams      calculate input params
     * @return  result          next timestamp for reaching threshold
     */
    function getNextThresholdTimestamp(MetadataCalcParams memory calcParams) internal view returns (uint256) {
        uint256 nextThresholdTimestamp = uint256(calcParams.currentTime);
        // chronosis
        nextThresholdTimestamp = Math.min(nextThresholdTimestamp,
                LibChronosis.getNextThresholdTimestamp(calcParams.chronosis, calcParams.rank, calcParams.coefficientWad, calcParams.exponential, calcParams.lastUpdateTime, calcParams.currentTime));

        // echo
        nextThresholdTimestamp = Math.min(nextThresholdTimestamp, 
                LibEcho.getNextThresholdTimestamp(calcParams.echo, calcParams.rank, calcParams.echoDecayRateWad, calcParams.exponential, calcParams.lastUpdateTime, calcParams.currentTime));
            
        // convergence
        nextThresholdTimestamp = Math.min(nextThresholdTimestamp, 
                LibConvergence.getNextThresholdTimestamp(calcParams.convergence, calcParams.rank, calcParams.convergenceDecayRateWad, calcParams.exponential, calcParams.lastUpdateTime, calcParams.currentTime));

        return uint64(nextThresholdTimestamp);
    }

    /**
     * batch update metadata
     * @dev will add more update metadata in the future
     * 
     * @param   calcParams      calculate input params
     * @return  updateValues    updated metadata value
     */
    function batchUpdate(MetadataCalcParams memory calcParams) internal view returns (
            UpdateValues memory updateValues
    ) {
        // for the nearest elapsed time for one of the metadatas' coming to its threshold, calculate other metadata's value at that moment
        // chronosis
        updateValues.chronosis = update(calcParams.lastUpdateTime, calcParams.nextThresholdTimestamp, calcParams.chronosis, calcParams.coefficientWad, calcParams.exponential);
            
        // echo
        updateValues.echo = update(calcParams.lastUpdateTime, calcParams.nextThresholdTimestamp, calcParams.echo, calcParams.echoDecayRateWad, calcParams.exponential);

        // convergence
        updateValues.convergence = update(calcParams.lastUpdateTime, calcParams.nextThresholdTimestamp, calcParams.convergence, calcParams.convergenceDecayRateWad, calcParams.exponential);
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
    function update(uint64 from, uint64 to, uint32 snapshot, uint256 decayRate, bool exponential) internal view returns(uint32 currentValue) {
        // 1. calculate elapsed minute from <from> to <to>
        uint256 elapsedMinute = Math.mulDiv(SafeMath.sub(to, from), 1, 60, Math.Rounding.Down);


        // 2. given current decay rate, exponential config, calculate updated value
        uint256 decayedValue = exponential ? decayRate * elapsedMinute * elapsedMinute : 
            decayRate * elapsedMinute;
        
        uint256 snapshotWad = toWadUnsafe(snapshot);

        uint256 currentValueWad = snapshotWad > decayedValue ?  snapshotWad - decayedValue : 0;

        // unwad current value
        currentValue = uint32(unWadUnsafe(currentValueWad));

    }

    function hasZero(MetadataCalcParams memory calcParams) internal pure returns (bool) {
        return calcParams.chronosis == 0 || calcParams.echo == 0 || calcParams.convergence == 0;
    }
}
