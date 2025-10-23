// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CCIPSender} from "../src/CCIPSender.sol";
import {CCIPMessageReceiver} from "../src/CCIPReceiver.sol";

contract DeployHedera is Script {
    // Hedera Testnet CCIP Router (Updated 2025)
    address constant HEDERA_ROUTER = 0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("HEDERA_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("");
        console.log("========================================");
        console.log("  DEPLOYING TO HEDERA TESTNET");
        console.log("========================================");
        console.log("");
        console.log("Network: Hedera Testnet");
        console.log("CCIP Router:", HEDERA_ROUTER);
        console.log("Deployer Address:", deployerAddress);
        console.log("Balance:", deployerAddress.balance / 1e18, "HBAR");
        console.log("");
        console.log("Deploying contracts...");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy sender contract
        CCIPSender sender = new CCIPSender(HEDERA_ROUTER);
        console.log("CCIPSender deployed to:", address(sender));

        // Deploy receiver contract
        CCIPMessageReceiver receiver = new CCIPMessageReceiver(HEDERA_ROUTER);
        console.log("CCIPMessageReceiver deployed to:", address(receiver));

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("  DEPLOYMENT SUCCESSFUL!");
        console.log("========================================");
        console.log("");
        console.log("Update your .env file with:");
        console.log("");
        console.log("HEDERA_SENDER_ADDRESS=", vm.toString(address(sender)));
        console.log("HEDERA_RECEIVER_ADDRESS=", vm.toString(address(receiver)));
        console.log("");
        console.log("Block Number:", block.number);
        console.log("");
        console.log("View on Hedera HashScan:");
        console.log("https://hashscan.io/testnet/contract/", vm.toString(address(sender)));
        console.log("https://hashscan.io/testnet/contract/", vm.toString(address(receiver)));
        console.log("");
        console.log("========================================");
        console.log("");
    }
}
