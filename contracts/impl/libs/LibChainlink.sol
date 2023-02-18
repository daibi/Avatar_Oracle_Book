// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { LibConstant } from "./LibConstant.sol";
import { ChainlinkRequestInterface } from "@chainlink/contracts/src/v0.8/interfaces/ChainlinkRequestInterface.sol";
import { LibAppStorage, AppStorage, PendingAPIRequest } from "../../storage/LibAppStorage.sol";
import { LibChainlinkProtocol } from "../../shared/libraries/LibChainlinkProtocol.sol";

/**
 * chainlink related library
 */
library LibChainlink {

    function buildChainlinkRequest(
        bytes32 specId,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    ) internal pure returns (Chainlink.Request memory) {
        Chainlink.Request memory req;
        return Chainlink.initialize(req, specId, callbackAddr, callbackFunctionSignature);
    }

    /**
     * @notice Creates a Chainlink request to the stored oracle address
     * @dev Calls `chainlinkRequestTo` with the stored oracle address
     * @param req The initialized Chainlink Request
     * @param tokenId token id
     * @param payment The amount of LINK to send for the request
     * @return requestId The request ID
     */
    function sendChainlinkRequest(Chainlink.Request memory req, uint256 tokenId, uint256 payment) internal returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return sendChainlinkRequestTo(address(s.s_oracle), req, tokenId, payment);
    }

    /**
     * @notice Creates a Chainlink request to the specified oracle address
     * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
     * send LINK which creates a request on the target oracle contract.
     * Emits ChainlinkRequested event.
     * @param oracleAddress The address of the oracle for the request
     * @param req The initialized Chainlink Request
     * @param payment The amount of LINK to send for the request
     * @return requestId The request ID
     */
    function sendChainlinkRequestTo(
        address oracleAddress,
        Chainlink.Request memory req,
        uint256 tokenId,
        uint256 payment
    ) internal returns (bytes32 requestId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 nonce = s.s_requestCount;
        s.s_requestCount = nonce + 1;
        bytes memory encodedRequest = abi.encodeWithSelector(
            ChainlinkRequestInterface.oracleRequest.selector,
            LibConstant.SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            LibConstant.AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            req.id,
            address(this),
            req.callbackFunctionId,
            nonce,
            LibConstant.ORACLE_ARGS_VERSION,
            req.buf.buf
        );
        return _rawRequest(oracleAddress, tokenId, nonce, payment, encodedRequest);
    }

    /**
     * @notice Make a request to an oracle
     * @param oracleAddress The address of the oracle for the request
     * @param nonce used to generate the request ID
     * @param payment The amount of LINK to send for the request
     * @param encodedRequest data encoded for request type specific format
     * @return requestId The request ID
     */
    function _rawRequest(
        address oracleAddress,
        uint256 tokenId,
        uint256 nonce,
        uint256 payment,
        bytes memory encodedRequest
    ) private returns (bytes32 requestId) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        requestId = keccak256(abi.encodePacked(this, nonce));
        s.s_pendingRequests[requestId] = PendingAPIRequest({
            oracleAddress: oracleAddress,
            tokenId: tokenId
        });
        emit LibChainlinkProtocol.ChainlinkRequested(requestId);
        require(s.s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
    }
}