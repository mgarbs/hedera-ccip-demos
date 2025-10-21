// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ICCIPRouter
 * @notice Interface for Chainlink CCIP Router
 */
interface ICCIPRouter {
    struct EVMTokenAmount {
        address token;
        uint256 amount;
    }

    struct EVM2AnyMessage {
        bytes receiver;
        bytes data;
        EVMTokenAmount[] tokenAmounts;
        address feeToken;
        bytes extraArgs;
    }

    /**
     * @notice Request a message to be sent to the destination chain
     * @param destinationChainSelector The destination chain selector
     * @param message The cross-chain CCIP message
     * @return messageId The message ID
     */
    function ccipSend(
        uint64 destinationChainSelector,
        EVM2AnyMessage calldata message
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Gets the fee required to send a CCIP message
     * @param destinationChainSelector The destination chain selector
     * @param message The cross-chain CCIP message
     * @return fee The fee amount
     */
    function getFee(
        uint64 destinationChainSelector,
        EVM2AnyMessage calldata message
    ) external view returns (uint256 fee);

    /**
     * @notice Gets the list of supported fee tokens for a destination chain
     * @param destinationChainSelector The destination chain selector
     * @return tokens Array of supported fee token addresses
     */
    function getSupportedTokens(
        uint64 destinationChainSelector
    ) external view returns (address[] memory tokens);
}
