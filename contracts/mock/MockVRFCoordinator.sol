//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract MockVRFCoordinator {

    event RandomWordsRequested(
        uint256 requestId,
        address indexed sender
    );

    event RandomWordsFulfilled(uint256 indexed requestId, bool success);

    uint256 internal counter = 123456;

    uint256 randomWord;

    function requestRandomWords(
        bytes32,
        uint64,
        uint16,
        uint32,
        uint32
    ) external returns (uint256 requestId) {
        counter += 1;
        randomWord = counter;
        requestId = counter;
        emit RandomWordsRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, address consumerAddress) external {
        VRFConsumerBaseV2 consumer = VRFConsumerBaseV2(consumerAddress);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomWord;
        consumer.rawFulfillRandomWords(requestId, randomWords);
        emit RandomWordsFulfilled(requestId, true);
    }

    function getCounter() external view returns (uint256 currentCounter) {
        currentCounter = counter;
    }
}