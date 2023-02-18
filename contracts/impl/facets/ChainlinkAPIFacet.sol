// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Modifiers } from '../../storage/LibAppStorage.sol';
import { LibChainlink } from '../libs/LibChainlink.sol';
import { LibConstant } from '../libs/LibConstant.sol';
import { LibUtils } from '../libs/LibUtils.sol';
import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";

contract ChainlinkAPIFacet is Modifiers {
    
    using Chainlink for Chainlink.Request;

    /**
     * request weather condtion for certain NFT
     * @param   locationId      id of location - request from accuweather /search API
     * @param   tokenId         token id for weather boost
     * 
     */
    function requestWeatherBoost(
        string memory locationId, 
        uint256 tokenId
    ) public returns (bytes32 requestId) {
        require(s.diamondAddress != address(0x0), 'diamond address is not initialized');
        require(s.chainlinkRequestFee != 0, 'chainlinkRequestFee is not initialized');
        Chainlink.Request memory req = LibChainlink.buildChainlinkRequest(
            s.jobId,
            s.diamondAddress,
            this.fulfill.selector
        );

        s.lastRequestURL = string(abi.encodePacked(
            "https://dataservice.accuweather.com/currentconditions/v1/",
            locationId,
            "?apikey=", s.accuWeatherApiKey
        ));

        // s.lastRequestURL = "https://dataservice.accuweather.com/currentconditions/v1/101924?apikey=Tcgdisc5DGZsPBfK6RgYgFFQY62beLSy";

        req.add(
            "get",
            s.lastRequestURL
        );

        req.add("path", "0,WeatherText");
        
        return LibChainlink.sendChainlinkRequest(req, tokenId, s.chainlinkRequestFee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        string memory _weather
    ) public recordChainlinkFulfillment(_requestId) {
        s.weather = _weather;
        s.weatherIcon = s.weatherMapping[LibUtils.stringToBytes32(_weather)];
        uint256 boostTokenId = s.s_pendingRequests[_requestId].tokenId;

        // Cloudy as default
        s.avatars[boostTokenId].boostSlots[LibConstant.WEATHER_BOOST_SLOT] = s.weatherIcon == 0 ? 
                s.weatherMapping[LibUtils.stringToBytes32("Cloudy")] : uint16(s.weatherIcon);
        
        s.avatars[boostTokenId].boostTimeRecorder[LibConstant.WEATHER_BOOST_SLOT] = uint64(block.timestamp);
        delete s.s_pendingRequests[_requestId];
    }

    function lastRequestURL() public view returns (string memory) {
        return s.lastRequestURL;
    }

    function weather() public view returns (string memory weather, uint8 weatherIcon) {
        weather = s.weather;
        weatherIcon = s.weatherIcon;
    }

    function queryConfigs() public view returns (
        address diamondAddress, 
        address s_oracle,
        address s_link,
        bytes32 jobId,
        string memory accuWeatherApiKey
    ) {
        diamondAddress = s.diamondAddress;
        s_oracle = address(s.s_oracle);
        s_link = address(s.s_link);
        jobId = s.jobId;
        accuWeatherApiKey = s.accuWeatherApiKey;
    }
}