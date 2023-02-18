// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibAppStorage, AppStorage } from '../storage/LibAppStorage.sol';
import { LibUtils } from '../impl/libs/LibUtils.sol';
import { OperatorInterface } from "@chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract ChainlinkOutsideAPIInit {

    function init(
        address diamondAddress, 
        string memory accuWeatherApiKey
    ) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        s.diamondAddress = diamondAddress;
        s.s_oracle = OperatorInterface(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        s.s_link = LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        s.jobId = "7da2702f37fd48e5b1b9a5715e3509b6";
        s.accuWeatherApiKey = accuWeatherApiKey;

        s.weatherMapping[LibUtils.stringToBytes32("Sunny")] = 1; 
        s.weatherMapping[LibUtils.stringToBytes32("Mostly Sunny")] = 2; 
        s.weatherMapping[LibUtils.stringToBytes32("Partly Sunny")] = 3; 
        s.weatherMapping[LibUtils.stringToBytes32("Intermittent Clouds")] = 4; 
        s.weatherMapping[LibUtils.stringToBytes32("Hazy Sunshine")] = 5; 
        s.weatherMapping[LibUtils.stringToBytes32("Mostly Cloudy")] = 6; 
        s.weatherMapping[LibUtils.stringToBytes32("Cloudy")] = 7; 
        s.weatherMapping[LibUtils.stringToBytes32("Dreary (Overcast)")] = 8; 
        s.weatherMapping[LibUtils.stringToBytes32("Fog")] = 11; 
        s.weatherMapping[LibUtils.stringToBytes32("Showers")] = 12; 
        s.weatherMapping[LibUtils.stringToBytes32("T-Storms")] = 15; 
        s.weatherMapping[LibUtils.stringToBytes32("Rain")] = 18; 
        s.weatherMapping[LibUtils.stringToBytes32("Flurries")] = 19; 
        s.weatherMapping[LibUtils.stringToBytes32("Snow")] = 20; 
        s.weatherMapping[LibUtils.stringToBytes32("Ice")] = 24; 
        s.weatherMapping[LibUtils.stringToBytes32("Sleet")] = 25; 
        s.weatherMapping[LibUtils.stringToBytes32("Freezing Rain")] = 26; 
        s.weatherMapping[LibUtils.stringToBytes32("Rain and Snow")] = 29; 
        s.weatherMapping[LibUtils.stringToBytes32("Hot")] = 30; 
        s.weatherMapping[LibUtils.stringToBytes32("Cold")] = 31; 
        s.weatherMapping[LibUtils.stringToBytes32("Windy")] = 32; 
        s.weatherMapping[LibUtils.stringToBytes32("Clear")] = 33; 

    }
}