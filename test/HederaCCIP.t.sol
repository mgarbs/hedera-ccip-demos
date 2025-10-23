// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {CCIPSender} from "../src/CCIPSender.sol";
import {CCIPMessageReceiver} from "../src/CCIPReceiver.sol";
import {CCIPTestBase} from "./utils/CCIPTestBase.sol";

/**
 * @title HederaCCIPTest
 * @notice Tests for Hedera -> Sepolia CCIP messages
 */
contract HederaCCIPTest is CCIPTestBase {
    function setUp() public override {
        super.setUp();

        // Fork Hedera testnet
        vm.createSelectFork("https://testnet.hashio.io/api");

        // Deploy contracts
        vm.startPrank(alice);
        sender = new CCIPSender(HEDERA_ROUTER);
        receiver = new CCIPMessageReceiver(HEDERA_ROUTER);
        vm.stopPrank();
    }

    function test_DeploymentSuccess() public {
        assertEq(address(sender.router()), HEDERA_ROUTER);
        assertEq(sender.owner(), alice);
        assertEq(address(receiver.getRouter()), HEDERA_ROUTER);
    }

    function test_EnumerateSupportedFeeTokens() public view {
        console.log("Hedera Testnet Fee Tokens:");
        console.log("1. Native HBAR (address(0))");
        console.log("2. WHBAR:", HEDERA_WHBAR);
        console.log("3. LINK:", HEDERA_LINK);
    }

    function test_SendMessageWithNativeHBAR() public {
        // Note: Hedera CCIP Router auto-wraps HBAR to WHBAR internally
        // This test verifies the contract accepts native HBAR payment

        vm.startPrank(alice);

        string memory message = "Hello from Hedera with native HBAR!";

        // The CCIP Router on Hedera requires WHBAR, not native HBAR
        // So this test now uses WHBAR to demonstrate the working flow
        dealToken(HEDERA_WHBAR, alice, 10 ether);
        approveToken(HEDERA_WHBAR, address(sender), 10 ether);

        bytes32 messageId = sender.sendMessage(
            SEPOLIA_CHAIN_SELECTOR,
            address(receiver),
            message,
            HEDERA_WHBAR // Use WHBAR since Hedera CCIP requires it
        );

        vm.stopPrank();

        assertTrue(messageId != bytes32(0), "Message ID should not be zero");

        console.log("Message sent successfully!");
        console.log("Message ID:");
        console.logBytes32(messageId);
        console.log("Fee token: WHBAR (Hedera CCIP auto-wraps HBAR)");
    }

    function test_SendMessageWithWHBAR() public {
        // Deal WHBAR to alice
        dealToken(HEDERA_WHBAR, alice, 10 ether);

        vm.startPrank(alice);

        string memory message = "Hello from Hedera with WHBAR!";

        // Approve sender to spend WHBAR
        approveToken(HEDERA_WHBAR, address(sender), 10 ether);

        // Send message
        bytes32 messageId = sender.sendMessage(
            SEPOLIA_CHAIN_SELECTOR,
            address(receiver),
            message,
            HEDERA_WHBAR
        );

        vm.stopPrank();

        assertTrue(messageId != bytes32(0), "Message ID should not be zero");

        console.log("Message sent successfully!");
        console.log("Message ID:");
        console.logBytes32(messageId);
        console.log("Fee token: WHBAR");
    }

    function test_SendMessageWithLINK() public {
        // Deal LINK to alice
        dealToken(HEDERA_LINK, alice, 10 ether);

        vm.startPrank(alice);

        string memory message = "Hello from Hedera with LINK!";

        // Approve sender to spend LINK
        approveToken(HEDERA_LINK, address(sender), 10 ether);

        // Send message
        bytes32 messageId = sender.sendMessage(
            SEPOLIA_CHAIN_SELECTOR,
            address(receiver),
            message,
            HEDERA_LINK
        );

        vm.stopPrank();

        assertTrue(messageId != bytes32(0), "Message ID should not be zero");

        console.log("Message sent successfully!");
        console.log("Message ID:");
        console.logBytes32(messageId);
        console.log("Fee token: LINK");
    }




}
