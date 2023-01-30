// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Math } from  "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { toWadUnsafe, unsafeWadDiv } from "../common/SignedWadMath.sol";
import "hardhat/console.sol";

/**
 * library for Chronosis calculation
 */
library LibChronosis {

    /**
     * get base decay rate for Chronosis by its current rank and value
     * @dev Decay rate can be exponential when current value is lower than a threshold proportional to the maximal Chronosis of current rank
     * 
     * @param   rank            avatar's current rank - will determine the maximal possible Chronosis value
     * @param   value           current Chronosis value
     * @return  coefficient     current decay coefficient against elapsed time
     * @return  exponential     determine whether the elapsed time effect to Chronosis becomes exponential
     */
    function getBaseDecayRate(
        uint8 rank, uint32 value
    ) pure internal returns(
        uint16 coefficient, 
        bool exponential
    ) {
        uint32 maxValue = getMaxValue(rank);
        require(maxValue > 0, "LibChronosis: invalid rank value!");

        // decay rate will become exponential when current value is lower than threshold
        exponential = getThreshold(maxValue) > value;
        coefficient = getCoefficient(exponential);
    }

    /**
     * get maximal possible Chronosis value given avatar's current rank
     * 
     * @param   rank            avatar's current rank
     * @return  maxValue        maximal possible Chronosis value of current rank
     */
    function getMaxValue(uint8 rank) internal pure returns (uint32 maxValue) {
        if (rank == 1) {
            // egg
            return 500;
        } 
        if (rank == 2) {
            // seed
            return 600;
        }
        if (rank == 3) {
            // Spirit
            return 750;
        }
        if (rank == 4) {
            // Doppleganger
            return 1000;
        }
    }

    /**
     * get threshold value for the decay rate of Chronosis becoming exponential
     *
     * @dev should guarantee that the maxValue is DIVIDABLE by your preset proportion     
     * 
     * @param   maxValue        Chornosis's current possible maximal value
     * @return  threshold       exponentially decaying threshold value
     */
    function getThreshold(uint256 maxValue) internal pure returns (uint256 threshold) {
        threshold = maxValue * 4 / 10;
    }

    /**
     * get current decaying coefficient
     * 
     * @dev current coefficient is the same for both status (either exponential or not), may become different for real implementation
     * 
     * @param   exponential     check if current decaying effect is exponential
     */
    function getCoefficient(bool exponential) internal pure returns (uint16 coefficient) {
        return exponential ? 20 : 20;
    }

    /**
     * get the next threshold timestamp for Chronosis
     * @dev the timestamp for reaching next threshold should not transcend currentTime
     * @dev the minimal decaying threshold should be ZERO(0)
     * 
     * @param   chronosis       current chronosis value
     * @param   rank            avatar rank
     * @param   coefficient     decay rate coefficient
     * @param   exponential     if current decay mode is in exponential
     * @param   lastUpdateTime  chronosis's last update time
     * @param   currentTime     current timestamp
     *
     * @return  nextTimestamp   timestamp for Chronosis's reaching its next threshold
     */
    function getNextThresholdTimestamp(
        uint32 chronosis, 
        uint8 rank,
        uint256 coefficient, 
        bool exponential,
        uint64 lastUpdateTime, 
        uint64 currentTime) internal view returns (uint256 nextTimestamp) {
        
        // 1. get the nearest next threshold value for Chronosis
        uint32 nextThreshold = getNextThresholdValue(chronosis, rank);

        // 2. get the difference between current value and threshold value
        uint32 difference = chronosis - nextThreshold;
        console.log("current chronosis: %d, nextThrehsold: %d, coefficient: %d", chronosis, nextThreshold, coefficient);
        console.log("current chronosis difference: %d", difference);


        // 3. get elapsed time needed for chronosis's reaching its threshold
        // Be AWARE: the difference should be waded to get into the elapsed time calculation
        // DO REMEMBER that the resulting time should NOT transcend current timestamp
        uint256 elapsedTime = exponential ? 
                Math.sqrt(Math.mulDiv(toWadUnsafe(difference), 1, coefficient, Math.Rounding.Up), Math.Rounding.Up) : 
                Math.mulDiv(toWadUnsafe(difference), 1, coefficient, Math.Rounding.Up);
        
        console.log("Elapsed time for chronosis's reaching next threshold: %d minute, threshold timestamp: %d, currentTime: %d", 
                elapsedTime, 
                lastUpdateTime + elapsedTime * 60, 
                currentTime
        );
        return Math.min(lastUpdateTime + elapsedTime * 60 , currentTime);
    }

    /**
     * given current chronosis value, get its next threshold value
     * @dev the threshold should NOT lower than ZERO
     * 
     * @param   chronosis       current chronosis value
     * @param   rank            avatar's rank
     * @return  nextThreshold   next threshold value
     */
    function getNextThresholdValue(uint32 chronosis, uint8 rank) internal pure returns (uint32 nextThreshold) {
        uint32 maxValue = getMaxValue(rank);
        uint256 threshold = getThreshold(maxValue);
        return chronosis > threshold ? uint32(threshold) : 0;
    }
}