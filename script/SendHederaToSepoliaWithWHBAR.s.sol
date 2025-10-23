// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CCIPSender} from "../src/CCIPSender.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract SendHederaToSepoliaWithWHBAR is Script {
    // Sepolia chain selector for CCIP
    uint64 constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;
    // Wrapped HBAR on Hedera Testnet (Updated 2025)
    address constant WHBAR = 0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("HEDERA_PRIVATE_KEY");
        address senderAddress = vm.envAddress("HEDERA_SENDER_ADDRESS");
        address receiverAddress = vm.envAddress("SEPOLIA_RECEIVER_ADDRESS");

        address deployerAddress = vm.addr(deployerPrivateKey);
        CCIPSender sender = CCIPSender(payable(senderAddress));

        console.log("");
        console.log("========================================");
        console.log("  HEDERA -> SEPOLIA (Pay with WHBAR)");
        console.log("========================================");
        console.log("");
        console.log("Source: Hedera Testnet");
        console.log("Destination: Sepolia Testnet");
        console.log("Sender Contract:", senderAddress);
        console.log("Receiver Contract:", receiverAddress);
        console.log("Your Address:", deployerAddress);
        console.log("");

        uint256 whbarBalance = IERC20(WHBAR).balanceOf(deployerAddress);
        console.log("Current Balances:");
        console.log("  HBAR:", deployerAddress.balance / 1e18, "HBAR");
        console.log("  WHBAR:", whbarBalance / 1e18, "WHBAR");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        string memory message = string(abi.encodePacked(
            "Hello from Hedera! Paid with wrapped HBAR at block ",
            vm.toString(block.number)
        ));

        console.log("Sending message:", message);
        console.log("");
        console.log("Approving 10 WHBAR for fees (excess stays in your wallet)...");

        // Approve sender contract to spend WHBAR
        IERC20(WHBAR).approve(senderAddress, 10 ether);

        console.log("Sending CCIP message...");

        // Send with WHBAR as fee token
        bytes32 messageId = sender.sendMessage(
            SEPOLIA_CHAIN_SELECTOR,
            receiverAddress,
            message,
            WHBAR
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
