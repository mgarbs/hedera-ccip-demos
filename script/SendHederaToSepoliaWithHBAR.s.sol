// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CCIPSender} from "../src/CCIPSender.sol";

contract SendHederaToSepoliaWithHBAR is Script {
    // Sepolia chain selector for CCIP
    uint64 constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("HEDERA_PRIVATE_KEY");
        address senderAddress = vm.envAddress("HEDERA_SENDER_ADDRESS");
        address receiverAddress = vm.envAddress("SEPOLIA_RECEIVER_ADDRESS");

        address deployerAddress = vm.addr(deployerPrivateKey);
        CCIPSender sender = CCIPSender(payable(senderAddress));

        console.log("");
        console.log("========================================");
        console.log("  HEDERA -> SEPOLIA (Pay with HBAR)");
        console.log("========================================");
        console.log("");
        console.log("Source: Hedera Testnet");
        console.log("Destination: Sepolia Testnet");
        console.log("Sender Contract:", senderAddress);
        console.log("Receiver Contract:", receiverAddress);
        console.log("Your Address:", deployerAddress);
        console.log("");
        console.log("Current Balance:", deployerAddress.balance / 1e18, "HBAR");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        string memory message = string(abi.encodePacked(
            "Hello from Hedera! Paid with native HBAR at block ",
            vm.toString(block.number)
        ));

        console.log("Sending message:", message);
        console.log("");
        console.log("Sending 5 HBAR (excess will remain in sender contract)...");

        // Send with native HBAR (address(0) as fee token)
        bytes32 messageId = sender.sendMessage{value: 5 ether}(
            SEPOLIA_CHAIN_SELECTOR,
            receiverAddress,
            message,
            address(0) // Native HBAR payment
        );

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("  TRANSACTION SUCCESSFUL!");
        console.log("========================================");
        console.log("");
        console.log("Message ID:");
        console.logBytes32(messageId);
        console.log("");
        console.log("Block Number:", block.number);
        console.log("Timestamp:", block.timestamp);
        console.log("");
        console.log("----------------------------------------");
        console.log("  Track Your Transaction");
        console.log("----------------------------------------");
        console.log("");
        console.log("CCIP Explorer:");
        console.log("https://ccip.chain.link/msg/", vm.toString(messageId));
        console.log("");
        console.log("Hedera HashScan:");
        console.log("https://hashscan.io/testnet/transaction/[YOUR_TX_HASH]");
        console.log("");
        console.log("----------------------------------------");
        console.log("  Verify on Destination");
        console.log("----------------------------------------");
        console.log("");
        console.log("Wait 10-20 minutes, then run:");
        console.log("");
        console.log("cast call", receiverAddress);
        console.log('  "getMessageCount()" --rpc-url sepolia');
        console.log("");
        console.log("cast call", receiverAddress);
        console.log('  "getLastMessage()" --rpc-url sepolia');
        console.log("");
        console.log("========================================");
        console.log("");
    }
}
