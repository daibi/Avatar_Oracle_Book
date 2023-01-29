// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Math } from  "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { toWadUnsafe, unsafeWadDiv } from "../common/SignedWadMath.sol";
import "hardhat/console.sol";

/**
 * Avatar metadata - Echo related library
 */
library LibEcho {

    /**
     * get affected chronosis decay rate coefficient by current Echo value
     * @dev should contain Wad since solidity doesn't support decimal calc
     * 
     * @param   rank                current avatar's rank
     * @param   echo                current echo value
     * @param   coefficientWad      current decay rate coefficient 
     * @param   exponential         check if current decay rate is exponential
     * 
     * @return  affectedCoefficientWad affected coefficient by current echo value
     */
    function getAffectedDecayRate(
        uint8 rank, 
        uint32 echo, 
        uint256 coefficientWad, 
        bool exponential) internal pure returns (uint256 affectedCoefficientWad) {
        
        uint256 maxValue = getMaxValue(rank);
        require(maxValue > 0, "LibEcho: invalid rank value!");

        if (echo >= maxValue * 2 / 5 && echo <= maxValue * 3 / 5) {
            // not affecting chronosis time decay
            affectedCoefficientWad = coefficientWad;
        } else if (echo > maxValue * 3 / 5) {
            assembly {
                affectedCoefficientWad := div(mul(coefficientWad, 4), 5)
            }
        } else {
            // affecting when echo value is below <40%> of current maximal value
            assembly {
                affectedCoefficientWad := div(mul(coefficientWad, 6), 5)
            }
        }
    }   

    /**
     * get correlated decay value for Echo
     * 
     * @param   coefficient          current decay rate coefficient wad
     *
     * @return  correlatedDecayRate  correlated decay value for Echo
     */
    function getCorrelateDecayRate(uint256 coefficient) internal pure returns(uint256 correlatedDecayRate) {
        assembly {
            correlatedDecayRate := div(mul(coefficient, 7), 10)
        }
    }

    /**
     * get the next threshold timestamp for Echo
     * @dev the timestamp for reaching next threshold should not transcend currentTime
     * @dev the minimal decaying threshold should be ZERO(0)
     * 
     * @param   echo            current echo value
     * @param   rank            avatar's rank
     * @param   echoDecayRate   echo decay rate
     * @param   exponential     if current decay mode is in exponential
     * @param   lastUpdateTime  chronosis's last update time
     * @param   currentTime     current timestamp
     *
     * @return  nextTimestamp   timestamp for Chronosis's reaching its next threshold
     */
    function getNextThresholdTimestamp(
        uint32 echo, 
        uint8 rank,
        uint256 echoDecayRate, 
        bool exponential,
        uint64 lastUpdateTime, 
        uint64 currentTime) internal view returns (uint256 nextTimestamp) {
        
        // 1. get the nearest next threshold value for Echo
        uint32 nextThreshold = getNextThresholdValue(echo, rank);

        // 2. get the difference between current value and threshold value
        uint32 difference = echo - nextThreshold;

        // 3. get elapsed time needed for echo's reaching its threshold
        // Be AWARE: the difference should be waded to get into the elapsed time calculation
        // DO REMEMBER that the resulting time should NOT transcend current timestamp
        uint256 elapsedTime = exponential ? 
                Math.sqrt(Math.mulDiv(toWadUnsafe(difference), 1, echoDecayRate, Math.Rounding.Up), Math.Rounding.Up) : 
                Math.mulDiv(toWadUnsafe(difference), 1, echoDecayRate, Math.Rounding.Up);
        
        console.log("Elapsed time for echo's reaching next threshold: %d minute, difference: %d, threshold timestamp: %d", 
                elapsedTime, 
                difference,
                lastUpdateTime + elapsedTime * 60
        );
        // 4. Since elapsed time is a minute interval, should transfer it into millisecond 
        return Math.min(lastUpdateTime + elapsedTime * 60, currentTime);
    }

    /**
     * given current echo value, get its next threshold value
     * @dev the threshold should NOT lower than ZERO
     * 
     * @param   echo            current echo value
     * @param   rank            avatar's rank
     * @return  nextThreshold   next threshold value
     */
    function getNextThresholdValue(uint32 echo, uint8 rank) internal pure returns (uint32 nextThreshold) {
        uint256 maxValue = getMaxValue(rank);

        uint256 firstThreshold;
        assembly {
            firstThreshold := div(mul(maxValue, 3), 5)
        }

        uint256 secondThreshold;
        assembly {
            secondThreshold := div(mul(maxValue, 2), 5)
        }

        if (echo > firstThreshold) {
            return uint32(firstThreshold);
        } else if (echo > secondThreshold) {
            return uint32(secondThreshold);
        }
        return 0;
    }

    /**
     * get maximal possible Echo value given avatar's current rank
     * 
     * @param   rank                current avatar's rank
     * 
     * @return  maxValue            maximal possible Echo value of current rank
     */
    function getMaxValue(uint8 rank) internal pure returns (uint256 maxValue) {
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
}