// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ICCIPRouter} from "../src/ICCIPRouter.sol";
import {IERC20} from "../src/IERC20.sol";

/**
 * @title SepoliaCCIPTest
 * @notice Tests for CCIP message sending from Ethereum Sepolia to Hedera Testnet
 * @dev Demonstrates two payment methods: native ETH and LINK
 *      Tests follow Chainlink's recommended pattern of tracking balance changes
 */
contract SepoliaCCIPTest is Test {
    // Sepolia Configuration
    ICCIPRouter constant SEPOLIA_ROUTER = ICCIPRouter(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);
    IERC20 constant LINK = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    // Hedera Chain Selector
    uint64 constant HEDERA_CHAIN_SELECTOR = 222782988166878823;

    // Test account
    address testAccount;

    // CCIP extra args for 200k gas limit
    bytes extraArgs = hex"97a657c90000000000000000000000000000000000000000000000000000000000030d40";

    function setUp() public {
        // Fork Sepolia
        vm.createSelectFork("sepolia");

        // Use the private key from environment or a default test account
        uint256 privateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        if (privateKey != 0) {
            testAccount = vm.addr(privateKey);
        } else {
            // Use a default test account
            testAccount = makeAddr("testAccount");
            // Fund the account with 1 ETH
            vm.deal(testAccount, 1 ether);
        }

        console.log("Testing with account:", testAccount);
        console.log("ETH balance:", testAccount.balance / 1e18, "ETH");
    }

    /**
     * @notice Test sending a CCIP message paying with native ETH
     * @dev This test demonstrates the Chainlink-recommended pattern:
     *      1. Record starting ETH balance
     *      2. Execute CCIP send with native payment
     *      3. Record ending ETH balance
     *      4. Assert balance difference equals fee paid
     */
    function test_SendMessageWithNativeETH() public {
        console.log("\n=== Test: Send CCIP Message with Native ETH ===");

        // Prepare the CCIP message
        string memory message = "Hello from Sepolia via CCIP, paid with native ETH!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(0), // address(0) indicates native token payment
            extraArgs: extraArgs
        });

        // Get the fee required for native ETH payment
        uint256 fee = SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (native ETH):", fee / 1e18, "ETH");

        // Record starting balance
        uint256 startingBalance = testAccount.balance;
        console.log("Starting ETH balance:", startingBalance / 1e18, "ETH");

        // Verify we have enough balance
        require(startingBalance >= fee, "Insufficient ETH balance for fee");

        // Send the CCIP message with native ETH payment
        vm.prank(testAccount);
        bytes32 messageId = SEPOLIA_ROUTER.ccipSend{value: fee}(
            HEDERA_CHAIN_SELECTOR,
            ccipMessage
        );

        // Record ending balance
        uint256 endingBalance = testAccount.balance;
        console.log("Ending ETH balance:", endingBalance / 1e18, "ETH");

        // Calculate the actual amount spent
        uint256 balanceDifference = startingBalance - endingBalance;
        console.log("Balance difference:", balanceDifference / 1e18, "ETH");

        // Assert that the balance difference equals the fee paid
        assertEq(
            balanceDifference,
            fee,
            "Balance difference should equal CCIP fee"
        );

        console.log("Message ID:", vm.toString(messageId));
        console.log("CCIP Explorer: https://ccip.chain.link/msg/", vm.toString(messageId));
        console.log("\nNative ETH payment successful!");
    }

    /**
     * @notice Test sending a CCIP message paying with LINK token
     * @dev Demonstrates ERC20 token payment with balance tracking
     */
    function test_SendMessageWithLINK() public {
        console.log("\n=== Test: Send CCIP Message with LINK ===");

        // Check LINK balance
        uint256 linkBalance = LINK.balanceOf(testAccount);
        console.log("LINK balance:", linkBalance / 1e18, "LINK");

        // Skip test if insufficient LINK
        if (linkBalance < 1e17) { // Less than 0.1 LINK
            console.log("WARNING: Skipping test: Insufficient LINK balance");
            console.log("Get LINK from: https://faucets.chain.link/sepolia");
            return;
        }

        // Prepare the CCIP message
        string memory message = "Hello from Sepolia via CCIP, paid with LINK!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(LINK), // Pay fee in LINK
            extraArgs: extraArgs
        });

        // Get the fee required for LINK payment
        uint256 fee = SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (LINK):", fee / 1e18, "LINK");

        // Record starting LINK balance
        uint256 startingBalance = LINK.balanceOf(testAccount);
        console.log("Starting LINK balance:", startingBalance / 1e18, "LINK");

        // Verify we have enough LINK
        require(startingBalance >= fee, "Insufficient LINK balance for fee");

        // Approve LINK for the router
        vm.prank(testAccount);
        LINK.approve(address(SEPOLIA_ROUTER), fee);

        // Send the CCIP message with LINK payment
        vm.prank(testAccount);
        bytes32 messageId = SEPOLIA_ROUTER.ccipSend(
            HEDERA_CHAIN_SELECTOR,
            ccipMessage
        );

        // Record ending LINK balance
        uint256 endingBalance = LINK.balanceOf(testAccount);
        console.log("Ending LINK balance:", endingBalance / 1e18, "LINK");

        // Calculate the actual amount spent
        uint256 balanceDifference = startingBalance - endingBalance;
        console.log("Balance difference:", balanceDifference / 1e18, "LINK");

        // Assert that the balance difference equals the fee paid
        assertEq(
            balanceDifference,
            fee,
            "LINK balance difference should equal CCIP fee"
        );

        console.log("Message ID:", vm.toString(messageId));
        console.log("CCIP Explorer: https://ccip.chain.link/msg/", vm.toString(messageId));
        console.log("\nLINK payment successful!");
    }

    /**
     * @notice Test comparing fees between native ETH and LINK payment
     */
    function test_CompareFees() public view {
        console.log("\n=== Fee Comparison ===");

        string memory message = "Test message for fee comparison";
        bytes memory encodedReceiver = abi.encode(testAccount);

        // Get fee for native ETH
        ICCIPRouter.EVM2AnyMessage memory nativeMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: extraArgs
        });
        uint256 feeInETH = SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, nativeMessage);

        // Get fee for LINK
        ICCIPRouter.EVM2AnyMessage memory linkMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(LINK),
            extraArgs: extraArgs
        });
        uint256 feeInLINK = SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, linkMessage);

        console.log("Native ETH fee:", feeInETH / 1e18, "ETH");
        console.log("LINK fee:", feeInLINK / 1e18, "LINK");
    }
}
