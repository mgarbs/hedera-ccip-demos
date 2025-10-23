// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract CCIPMessageReceiver is CCIPReceiver {
    struct Message {
        uint64 sourceChainSelector;
        address sender;
        string message;
        uint256 timestamp;
    }

    // Array to store all received messages
    Message[] public receivedMessages;

    // Event emitted when a message is received
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        string message
    );

    constructor(address router) CCIPReceiver(router) {}

    /// @notice Internal function to handle incoming CCIP messages
    /// @param message The CCIP message
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        address sender = abi.decode(message.sender, (address));
        string memory text = abi.decode(message.data, (string));

        // Store the received message
        receivedMessages.push(
            Message({
                sourceChainSelector: message.sourceChainSelector,
                sender: sender,
                message: text,
                timestamp: block.timestamp
            })
        );

        emit MessageReceived(
            message.messageId,
            message.sourceChainSelector,
            sender,
            text
        );
    }

    /// @notice Get the total number of received messages
    function getMessageCount() external view returns (uint256) {
        return receivedMessages.length;
    }

    /// @notice Get a specific message by index
    function getMessage(uint256 index) external view returns (Message memory) {
        require(index < receivedMessages.length, "Index out of bounds");
        return receivedMessages[index];
    }

    /// @notice Get the last received message
    function getLastMessage() external view returns (Message memory) {
        require(receivedMessages.length > 0, "No messages received");
        return receivedMessages[receivedMessages.length - 1];
    }

    /// @notice Get all received messages
    function getAllMessages() external view returns (Message[] memory) {
        return receivedMessages;
    }
}
