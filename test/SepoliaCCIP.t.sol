// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {CCIPSender} from "../src/CCIPSender.sol";
import {CCIPMessageReceiver} from "../src/CCIPReceiver.sol";
import {CCIPTestBase} from "./utils/CCIPTestBase.sol";

/**
 * @title SepoliaCCIPTest
 * @notice Tests for Sepolia -> Hedera CCIP messages
 */
contract SepoliaCCIPTest is CCIPTestBase {
    function setUp() public override {
        super.setUp();

        // Fork Sepolia testnet
        vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"));

        // Deploy contracts
        vm.startPrank(alice);
        sender = new CCIPSender(SEPOLIA_ROUTER);
        receiver = new CCIPMessageReceiver(SEPOLIA_ROUTER);
        vm.stopPrank();
    }

    function test_DeploymentSuccess() public {
        assertEq(address(sender.router()), SEPOLIA_ROUTER);
        assertEq(sender.owner(), alice);
        assertEq(address(receiver.getRouter()), SEPOLIA_ROUTER);
    }

    function test_EnumerateSupportedFeeTokens() public view {
        console.log("Sepolia Testnet Fee Tokens:");
        console.log("1. Native ETH (address(0))");
        console.log("2. LINK:", SEPOLIA_LINK);
    }


    function test_SendMessageWithLINK() public {
        // Deal LINK to alice
        dealToken(SEPOLIA_LINK, alice, 10 ether);

        vm.startPrank(alice);

        string memory message = "Hello from Sepolia with LINK!";

        // Approve sender to spend LINK
        approveToken(SEPOLIA_LINK, address(sender), 10 ether);

        // Send message
        bytes32 messageId = sender.sendMessage(
            HEDERA_CHAIN_SELECTOR,
            address(receiver),
            message,
            SEPOLIA_LINK
        );

        vm.stopPrank();

        assertTrue(messageId != bytes32(0), "Message ID should not be zero");

        console.log("Message sent successfully!");
        console.log("Message ID:");
        console.logBytes32(messageId);
        console.log("Fee token: LINK");
    }





}
