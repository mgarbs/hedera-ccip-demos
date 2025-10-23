// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CCIPSender} from "../src/CCIPSender.sol";
import {CCIPMessageReceiver} from "../src/CCIPReceiver.sol";

contract DeploySepolia is Script {
    // Sepolia CCIP Router
    address constant SEPOLIA_ROUTER = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("");
        console.log("========================================");
        console.log("  DEPLOYING TO SEPOLIA TESTNET");
        console.log("========================================");
        console.log("");
        console.log("Network: Sepolia Testnet");
        console.log("CCIP Router:", SEPOLIA_ROUTER);
        console.log("Deployer Address:", deployerAddress);
        console.log("Balance:", deployerAddress.balance / 1e18, "ETH");
        console.log("");
        console.log("Deploying contracts...");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy sender contract
        CCIPSender sender = new CCIPSender(SEPOLIA_ROUTER);
        console.log("CCIPSender deployed to:", address(sender));

        // Deploy receiver contract
        CCIPMessageReceiver receiver = new CCIPMessageReceiver(SEPOLIA_ROUTER);
        console.log("CCIPMessageReceiver deployed to:", address(receiver));

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("  DEPLOYMENT SUCCESSFUL!");
        console.log("========================================");
        console.log("");
        console.log("Update your .env file with:");
        console.log("");
        console.log("SEPOLIA_SENDER_ADDRESS=", vm.toString(address(sender)));
        console.log("SEPOLIA_RECEIVER_ADDRESS=", vm.toString(address(receiver)));
        console.log("");
        console.log("Block Number:", block.number);
        console.log("");
        console.log("View on Sepolia Etherscan:");
        console.log("https://sepolia.etherscan.io/address/", vm.toString(address(sender)));
        console.log("https://sepolia.etherscan.io/address/", vm.toString(address(receiver)));
        console.log("");
        console.log("========================================");
        console.log("");
    }
}
