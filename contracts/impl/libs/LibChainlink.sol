// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { LibAppStorage, AppStorage } from "../../storage/LibAppStorage.sol";

/**
 * chainlink related library
 */
library LibChainlink {

    using Chainlink for Chainlink.Request;

    function buildChainlinkRequest(
        bytes32 specId,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    ) internal pure returns (Chainlink.Request memory) {
        Chainlink.Request memory req;
        return req.initialize(specId, callbackAddr, callbackFunctionSignature);
    }

    /**
     * @notice Creates a Chainlink request to the stored oracle address
     * @dev Calls `chainlinkRequestTo` with the stored oracle address
     * @param req The initialized Chainlink Request
     * @param payment The amount of LINK to send for the request
     * @return requestId The request ID
     */
    function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return sendChainlinkRequestTo(address(s.s_oracle), req, payment);
    }

    
}