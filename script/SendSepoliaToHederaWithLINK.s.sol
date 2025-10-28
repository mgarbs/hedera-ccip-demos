// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CCIPSender} from "../src/CCIPSender.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract SendSepoliaToHederaWithLINK is Script {
    // Hedera Testnet chain selector for CCIP
    uint64 constant HEDERA_CHAIN_SELECTOR = 222782988166878823;
    // LINK token on Sepolia
    address constant LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        address senderAddress = vm.envAddress("SEPOLIA_SENDER_ADDRESS");
        address receiverAddress = vm.envAddress("HEDERA_RECEIVER_ADDRESS");

        address deployerAddress = vm.addr(deployerPrivateKey);
        CCIPSender sender = CCIPSender(payable(senderAddress));

        console.log("");
        console.log("========================================");
        console.log("  SEPOLIA -> HEDERA (Pay with LINK)");
        console.log("========================================");
        console.log("");
        console.log("Source: Sepolia Testnet");
        console.log("Destination: Hedera Testnet");
        console.log("Sender Contract:", senderAddress);
        console.log("Receiver Contract:", receiverAddress);
        console.log("Your Address:", deployerAddress);
        console.log("");

        uint256 linkBalance = IERC20(LINK).balanceOf(deployerAddress);
        console.log("Current Balances:");
        console.log("  ETH:", deployerAddress.balance / 1e18, "ETH");
        console.log("  LINK:", linkBalance / 1e18, "LINK");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        string memory message = string(
            abi.encodePacked(
                "Hello from Sepolia! Paid with LINK at block ",
                vm.toString(block.number)
            )
        );

        console.log("Sending message:", message);
        console.log("");
        console.log(
            "Approving 1 LINK for fees (excess stays in your wallet)..."
        );

        // Approve sender contract to spend LINK
        IERC20(LINK).approve(senderAddress, 1 ether);

        console.log("Sending CCIP message...");

        // Send with LINK as fee token
        bytes32 messageId = sender.sendMessage(
            HEDERA_CHAIN_SELECTOR,
            receiverAddress,
            message,
            LINK
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
        console.log(
            string.concat(
                "https://ccip.chain.link/msg/",
                vm.toString(messageId)
            )
        );
        console.log("");
        console.log("Sepolia Etherscan:");
        console.log(
            string.concat(
                "https://sepolia.etherscan.io/tx/",
                vm.toString(messageId)
            )
        );
        console.log("");
        console.log("----------------------------------------");
        console.log("  Verify on Destination");
        console.log("----------------------------------------");
        console.log("");
        console.log("Wait 10-20 minutes, then run:");
        console.log("");
        console.log("cast call", receiverAddress);
        console.log('  "getMessageCount()" --rpc-url hedera_testnet');
        console.log("");
        console.log("cast call", receiverAddress);
        console.log('  "getLastMessage()" --rpc-url hedera_testnet');
        console.log("");
        console.log("========================================");
        console.log("");
    }
}
