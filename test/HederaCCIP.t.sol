// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ICCIPRouter} from "../src/ICCIPRouter.sol";
import {IERC20} from "../src/IERC20.sol";

/**
 * @title HederaCCIPTest
 * @notice Tests for CCIP message sending from Hedera Testnet to Ethereum Sepolia
 * @dev Demonstrates three payment methods: native HBAR, WHBAR, and LINK
 *      Tests follow Chainlink's recommended pattern of tracking balance changes
 */
contract HederaCCIPTest is Test {
    // Hedera Testnet Configuration
    ICCIPRouter constant HEDERA_ROUTER = ICCIPRouter(0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4);
    IERC20 constant LINK = IERC20(0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6);
    IERC20 constant WHBAR = IERC20(0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed);

    // Sepolia Chain Selector
    uint64 constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;

    // Test account
    address testAccount;

    // CCIP extra args for 200k gas limit
    bytes extraArgs = hex"97a657c90000000000000000000000000000000000000000000000000000000000030d40";

    function setUp() public {
        // Fork Hedera Testnet
        vm.createSelectFork("hedera_testnet");

        // Use the private key from environment or a default test account
        uint256 privateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        if (privateKey != 0) {
            testAccount = vm.addr(privateKey);
        } else {
            // Use a default test account
            testAccount = makeAddr("testAccount");
            // Fund the account with 10 HBAR
            vm.deal(testAccount, 10 ether);
        }

        console.log("Testing with account:", testAccount);
        console.log("HBAR balance:", testAccount.balance / 1e18, "HBAR");
    }

    /**
     * @notice Test sending a CCIP message paying with native HBAR
     * @dev This test demonstrates the Chainlink-recommended pattern:
     *      1. Record starting HBAR balance
     *      2. Execute CCIP send with native payment
     *      3. Record ending HBAR balance
     *      4. Assert balance difference equals fee paid
     */
    function test_SendMessageWithNativeHBAR() public {
        console.log("\n=== Test: Send CCIP Message with Native HBAR ===");

        // Prepare the CCIP message
        string memory message = "Hello from Hedera via CCIP, paid with native HBAR!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(0), // address(0) indicates native token payment
            extraArgs: extraArgs
        });

        // Get the fee required for native HBAR payment
        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (native HBAR):", fee / 1e18, "HBAR");

        // Record starting balance
        uint256 startingBalance = testAccount.balance;
        console.log("Starting HBAR balance:", startingBalance / 1e18, "HBAR");

        // Verify we have enough balance
        require(startingBalance >= fee, "Insufficient HBAR balance for fee");

        // Send the CCIP message with native HBAR payment
        vm.prank(testAccount);
        bytes32 messageId = HEDERA_ROUTER.ccipSend{value: fee}(
            SEPOLIA_CHAIN_SELECTOR,
            ccipMessage
        );

        // Record ending balance
        uint256 endingBalance = testAccount.balance;
        console.log("Ending HBAR balance:", endingBalance / 1e18, "HBAR");

        // Calculate the actual amount spent
        uint256 balanceDifference = startingBalance - endingBalance;
        console.log("Balance difference:", balanceDifference / 1e18, "HBAR");

        // Assert that the balance difference equals the fee paid
        assertEq(
            balanceDifference,
            fee,
            "Balance difference should equal CCIP fee"
        );

        console.log("Message ID:", vm.toString(messageId));
        console.log("CCIP Explorer: https://ccip.chain.link/msg/", vm.toString(messageId));
        console.log("\nNative HBAR payment successful!");
    }

    /**
     * @notice Test sending a CCIP message paying with Wrapped HBAR (WHBAR)
     * @dev WHBAR uses 8 decimals (not 18 like most ERC20 tokens)
     *      Demonstrates ERC20 token payment with balance tracking
     */
    function test_SendMessageWithWHBAR() public {
        console.log("\n=== Test: Send CCIP Message with Wrapped HBAR ===");

        // Check WHBAR balance
        uint256 whbarBalance = WHBAR.balanceOf(testAccount);
        console.log("WHBAR balance:", whbarBalance / 1e8, "WHBAR");

        // Skip test if insufficient WHBAR
        if (whbarBalance < 1e8) {
            console.log("WARNING: Skipping test: Insufficient WHBAR balance");
            console.log("Run: pnpm run wrap-hbar");
            return;
        }

        // Prepare the CCIP message
        string memory message = "Hello from Hedera via CCIP, paid with WHBAR!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(WHBAR), // Pay fee in WHBAR
            extraArgs: extraArgs
        });

        // Get the fee required for WHBAR payment
        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (WHBAR):", fee / 1e8, "WHBAR");

        // Record starting WHBAR balance
        uint256 startingBalance = WHBAR.balanceOf(testAccount);
        console.log("Starting WHBAR balance:", startingBalance / 1e8, "WHBAR");

        // Verify we have enough WHBAR
        require(startingBalance >= fee, "Insufficient WHBAR balance for fee");

        // Approve WHBAR for the router
        vm.prank(testAccount);
        WHBAR.approve(address(HEDERA_ROUTER), fee);

        // Send the CCIP message with WHBAR payment
        vm.prank(testAccount);
        bytes32 messageId = HEDERA_ROUTER.ccipSend(
            SEPOLIA_CHAIN_SELECTOR,
            ccipMessage
        );

        // Record ending WHBAR balance
        uint256 endingBalance = WHBAR.balanceOf(testAccount);
        console.log("Ending WHBAR balance:", endingBalance / 1e8, "WHBAR");

        // Calculate the actual amount spent
        uint256 balanceDifference = startingBalance - endingBalance;
        console.log("Balance difference:", balanceDifference / 1e8, "WHBAR");

        // Assert that the balance difference equals the fee paid
        assertEq(
            balanceDifference,
            fee,
            "WHBAR balance difference should equal CCIP fee"
        );

        console.log("Message ID:", vm.toString(messageId));
        console.log("CCIP Explorer: https://ccip.chain.link/msg/", vm.toString(messageId));
        console.log("\nWHBAR payment successful!");
    }

    /**
     * @notice Test sending a CCIP message paying with LINK token
     * @dev Demonstrates standard ERC20 (18 decimals) token payment with balance tracking
     */
    function test_SendMessageWithLINK() public {
        console.log("\n=== Test: Send CCIP Message with LINK ===");

        // Check LINK balance
        uint256 linkBalance = LINK.balanceOf(testAccount);
        console.log("LINK balance:", linkBalance / 1e18, "LINK");

        // Skip test if insufficient LINK
        if (linkBalance < 1e17) { // Less than 0.1 LINK
            console.log("WARNING: Skipping test: Insufficient LINK balance");
            console.log("Get LINK from: https://faucets.chain.link/hedera-testnet");
            return;
        }

        // Prepare the CCIP message
        string memory message = "Hello from Hedera via CCIP, paid with LINK!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(LINK), // Pay fee in LINK
            extraArgs: extraArgs
        });

        // Get the fee required for LINK payment
        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (LINK):", fee / 1e18, "LINK");

        // Record starting LINK balance
        uint256 startingBalance = LINK.balanceOf(testAccount);
        console.log("Starting LINK balance:", startingBalance / 1e18, "LINK");

        // Verify we have enough LINK
        require(startingBalance >= fee, "Insufficient LINK balance for fee");

        // Approve LINK for the router
        vm.prank(testAccount);
        LINK.approve(address(HEDERA_ROUTER), fee);

        // Send the CCIP message with LINK payment
        vm.prank(testAccount);
        bytes32 messageId = HEDERA_ROUTER.ccipSend(
            SEPOLIA_CHAIN_SELECTOR,
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
     * @notice Test to check supported tokens (read-only)
     */
    function test_GetSupportedTokens() public view {
        console.log("\n=== Supported Fee Tokens ===");
        address[] memory tokens = HEDERA_ROUTER.getSupportedTokens(SEPOLIA_CHAIN_SELECTOR);
        console.log("Number of supported tokens:", tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            console.log("Token", i, ":", tokens[i]);
            if (tokens[i] == address(LINK)) {
                console.log("  -> LINK");
            } else if (tokens[i] == address(WHBAR)) {
                console.log("  -> WHBAR");
            }
        }
    }

    /**
     * @notice Test comparing fees across all payment methods
     */
    function test_CompareFees() public view {
        console.log("\n=== Fee Comparison ===");

        string memory message = "Test message for fee comparison";
        bytes memory encodedReceiver = abi.encode(testAccount);

        // Get fee for native HBAR
        ICCIPRouter.EVM2AnyMessage memory nativeMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: extraArgs
        });
        uint256 feeInHBAR = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, nativeMessage);

        // Get fee for WHBAR
        ICCIPRouter.EVM2AnyMessage memory whbarMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(WHBAR),
            extraArgs: extraArgs
        });
        uint256 feeInWHBAR = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, whbarMessage);

        // Get fee for LINK
        ICCIPRouter.EVM2AnyMessage memory linkMessage = ICCIPRouter.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: abi.encode(message),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(LINK),
            extraArgs: extraArgs
        });
        uint256 feeInLINK = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, linkMessage);

        console.log("Native HBAR fee:", feeInHBAR / 1e18, "HBAR");
        console.log("WHBAR fee:", feeInWHBAR / 1e8, "WHBAR");
        console.log("LINK fee:", feeInLINK / 1e18, "LINK");
    }
}
