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
    ICCIPRouter constant HEDERA_ROUTER =
        ICCIPRouter(0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4);
    IERC20 constant LINK = IERC20(0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6);
    IERC20 constant WHBAR = IERC20(0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed);

    // Sepolia Chain Selector
    uint64 constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;

    // Test account
    address testAccount;

    // CCIP extra args for 200k gas limit
    bytes extraArgs =
        hex"97a657c90000000000000000000000000000000000000000000000000000000000030d40";

    function setUp() public {
        // Fork Hedera Testnet
        vm.createSelectFork("hedera_testnet");

        // Use the private key from environment or a default test account
        uint256 privateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        // Minimal hex fallback (supports PRIVATE_KEY=0x...)
        if (privateKey == 0) {
            try vm.envBytes32("PRIVATE_KEY") returns (bytes32 pk) {
                privateKey = uint256(pk);
            } catch {}
        }

        if (privateKey != 0) {
            testAccount = vm.addr(privateKey);
        } else {
            // Use a default test account
            testAccount = makeAddr("testAccount");
            // Fund the account with 10 HBAR (local fork funding)
            vm.deal(testAccount, 10 ether);
        }

        console.log("Testing with account:", testAccount);
        _logNativeBalance(testAccount, "HBAR");
    }

    /**
     * @notice Test sending a CCIP message paying with native HBAR
     * @dev For native tests, set gas price to 0 so balance delta equals fee exactly.
     */
    function test_SendMessageWithNativeHBAR() public {
        console.log("\n=== Test: Send CCIP Message with Native HBAR ===");

        // Prepare the CCIP message
        string
            memory message = "Hello from Hedera via CCIP, paid with native HBAR!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter
            .EVM2AnyMessage({
                receiver: encodedReceiver,
                data: abi.encode(message),
                tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
                feeToken: address(0), // address(0) indicates native token payment
                extraArgs: extraArgs
            });

        // Get the fee required for native HBAR payment
        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (HBAR, wei):", fee);
        console.log("CCIP fee (~6dp):", _toFixed6(fee), "HBAR");

        // Record starting balance
        uint256 startingBalance = testAccount.balance;
        console.log("Starting HBAR balance (wei):", startingBalance);
        console.log(
            "Starting HBAR balance (~6dp):",
            _toFixed6(startingBalance),
            "HBAR"
        );

        // Verify we have enough balance
        require(startingBalance >= fee, "Insufficient HBAR balance for fee");

        // Ensure gas doesn't skew native balance delta
        vm.txGasPrice(0);

        // Send the CCIP message with native HBAR payment
        vm.prank(testAccount);
        bytes32 messageId = HEDERA_ROUTER.ccipSend{value: fee}(
            SEPOLIA_CHAIN_SELECTOR,
            ccipMessage
        );

        // Record ending balance
        uint256 endingBalance = testAccount.balance;
        console.log("Ending HBAR balance (wei):", endingBalance);
        console.log(
            "Ending HBAR balance (~6dp):",
            _toFixed6(endingBalance),
            "HBAR"
        );

        // Calculate the actual amount spent
        uint256 balanceDifference = startingBalance - endingBalance;
        console.log("Balance difference (wei):", balanceDifference);
        console.log(
            "Balance difference (~6dp):",
            _toFixed6(balanceDifference),
            "HBAR"
        );

        // Assert that the balance difference equals the fee paid
        assertEq(
            balanceDifference,
            fee,
            "Native balance difference should equal CCIP fee (gas price forced to 0)"
        );

        console.log(
            string.concat(
                "CCIP Explorer: https://ccip.chain.link/msg/",
                vm.toString(messageId)
            )
        );
        console.log("\nNative HBAR payment successful!");
    }

    /**
     * @notice Test sending a CCIP message paying with Wrapped HBAR (WHBAR)
     * @dev WHBAR uses 8 decimals (not 18)
     */
    function test_SendMessageWithWHBAR() public {
        console.log("\n=== Test: Send CCIP Message with Wrapped HBAR ===");

        // Check WHBAR balance
        uint256 whbarBalance = WHBAR.balanceOf(testAccount);
        console.log("WHBAR balance (raw):", whbarBalance);
        console.log("WHBAR balance:", whbarBalance / 1e8, "WHBAR");

        // Skip test if insufficient WHBAR
        if (whbarBalance < 1e8) {
            console.log("WARNING: Skipping test: Insufficient WHBAR balance");
            console.log(
                "See README: Wrap HBAR to WHBAR via forge script or cast."
            );
            return;
        }

        // Prepare the CCIP message
        string memory message = "Hello from Hedera via CCIP, paid with WHBAR!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter
            .EVM2AnyMessage({
                receiver: encodedReceiver,
                data: abi.encode(message),
                tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
                feeToken: address(WHBAR), // Pay fee in WHBAR
                extraArgs: extraArgs
            });

        // Get the fee required for WHBAR payment
        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (WHBAR raw):", fee);
        console.log("CCIP fee (WHBAR):", fee / 1e8, "WHBAR");

        // Record starting WHBAR balance
        uint256 startingBalance = WHBAR.balanceOf(testAccount);
        console.log("Starting WHBAR balance (raw):", startingBalance);
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
        console.log("Ending WHBAR balance (raw):", endingBalance);
        console.log("Ending WHBAR balance:", endingBalance / 1e8, "WHBAR");

        // Calculate the actual amount spent
        uint256 balanceDifference = startingBalance - endingBalance;
        console.log("Balance difference (raw):", balanceDifference);
        console.log("Balance difference:", balanceDifference / 1e8, "WHBAR");

        // Assert that the balance difference equals the fee paid
        assertEq(
            balanceDifference,
            fee,
            "WHBAR balance difference should equal CCIP fee"
        );

        console.log(
            string.concat(
                "CCIP Explorer: https://ccip.chain.link/msg/",
                vm.toString(messageId)
            )
        );
        console.log("\nWHBAR payment successful!");
    }

    /**
     * @notice Test sending a CCIP message paying with LINK token
     */
    function test_SendMessageWithLINK() public {
        console.log("\n=== Test: Send CCIP Message with LINK ===");

        // Check LINK balance
        uint256 linkBalance = LINK.balanceOf(testAccount);
        console.log("LINK balance (raw):", linkBalance);
        console.log("LINK balance:", linkBalance / 1e18, "LINK");

        // Skip test if insufficient LINK
        if (linkBalance < 1e17) {
            // Less than 0.1 LINK
            console.log("WARNING: Skipping test: Insufficient LINK balance");
            console.log(
                "Get LINK from: https://faucets.chain.link/hedera-testnet"
            );
            return;
        }

        // Prepare the CCIP message
        string memory message = "Hello from Hedera via CCIP, paid with LINK!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter
            .EVM2AnyMessage({
                receiver: encodedReceiver,
                data: abi.encode(message),
                tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
                feeToken: address(LINK), // Pay fee in LINK
                extraArgs: extraArgs
            });

        // Get the fee required for LINK payment
        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (LINK raw):", fee);
        console.log("CCIP fee (LINK):", fee / 1e18, "LINK");

        // Record starting LINK balance
        uint256 startingBalance = LINK.balanceOf(testAccount);
        console.log("Starting LINK balance (raw):", startingBalance);
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
        console.log("Ending LINK balance (raw):", endingBalance);
        console.log("Ending LINK balance:", endingBalance / 1e18, "LINK");

        // Calculate the actual amount spent
        uint256 balanceDifference = startingBalance - endingBalance;
        console.log("Balance difference (raw):", balanceDifference);
        console.log("Balance difference:", balanceDifference / 1e18, "LINK");

        // Assert that the balance difference equals the fee paid
        assertEq(
            balanceDifference,
            fee,
            "LINK balance difference should equal CCIP fee"
        );

        console.log(
            string.concat(
                "CCIP Explorer: https://ccip.chain.link/msg/",
                vm.toString(messageId)
            )
        );
        console.log("\nLINK payment successful!");
    }

    /**
     * @notice Test to check supported tokens. Falls back to probing when router has removed the function.
     */
    function test_GetSupportedTokens() public view {
        console.log("\n=== Supported Fee Tokens ===");
        // First try the (now removed on current routers) function
        try HEDERA_ROUTER.getSupportedTokens(SEPOLIA_CHAIN_SELECTOR) returns (
            address[] memory tokens
        ) {
            console.log("Number of supported tokens:", tokens.length);
            for (uint i = 0; i < tokens.length; i++) {
                console.log("Token", i, ":", tokens[i]);
                if (tokens[i] == address(LINK)) {
                    console.log("  -> LINK");
                } else if (tokens[i] == address(WHBAR)) {
                    console.log("  -> WHBAR");
                } else if (tokens[i] == address(0)) {
                    console.log("  -> NATIVE HBAR");
                }
            }
        } catch (bytes memory reason) {
            // Decode first 4 bytes of revert to confirm it's the “functionality removed” error
            bytes4 sel;
            if (reason.length >= 4) {
                assembly {
                    sel := mload(add(reason, 0x20))
                }
            }
            console.log(
                "getSupportedTokens reverted; likely removed on this router."
            );
            console.log("Revert selector:", vm.toString(sel));
            console.log(
                "Tip: probe support via getFee with specific feeToken addresses."
            );

            // Fallback: probe candidate tokens using getFee
            address[] memory candidates = new address[](3);
            string[] memory labels = new string[](3);
            candidates[0] = address(0);
            labels[0] = "HBAR(native)";
            candidates[1] = address(LINK);
            labels[1] = "LINK";
            candidates[2] = address(WHBAR);
            labels[2] = "WHBAR";

            bytes memory encodedReceiver = abi.encode(testAccount);
            string memory probeMsg = "probe";

            uint256 found = 0;
            for (uint i = 0; i < candidates.length; i++) {
                ICCIPRouter.EVM2AnyMessage memory m = ICCIPRouter
                    .EVM2AnyMessage({
                        receiver: encodedReceiver,
                        data: abi.encode(probeMsg),
                        tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
                        feeToken: candidates[i],
                        extraArgs: extraArgs
                    });
                try HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, m) returns (
                    uint256 /*fee*/
                ) {
                    found++;
                    console.log(
                        "Supported fee token:",
                        labels[i],
                        candidates[i]
                    );
                } catch {
                    console.log("Not supported:", labels[i], candidates[i]);
                }
            }
            console.log("Total supported (by probing):", found);
        }
    }

    /**
     * @notice Explicit probing-only test to enumerate supported tokens on this lane.
     */
    function test_ListSupportedFeeTokensByProbing() public view {
        console.log(
            "\n=== Enumerating supported fee tokens by probing (Hedera -> Sepolia) ==="
        );
        address[] memory candidates = new address[](3);
        string[] memory labels = new string[](3);
        candidates[0] = address(0);
        labels[0] = "HBAR(native)";
        candidates[1] = address(LINK);
        labels[1] = "LINK";
        candidates[2] = address(WHBAR);
        labels[2] = "WHBAR";

        bytes memory encodedReceiver = abi.encode(testAccount);
        string memory probeMsg = "probe";
        uint256 found = 0;

        for (uint i = 0; i < candidates.length; i++) {
            ICCIPRouter.EVM2AnyMessage memory m = ICCIPRouter.EVM2AnyMessage({
                receiver: encodedReceiver,
                data: abi.encode(probeMsg),
                tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
                feeToken: candidates[i],
                extraArgs: extraArgs
            });
            try HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, m) returns (
                uint256 /*fee*/
            ) {
                found++;
                console.log("Supported fee token:", labels[i], candidates[i]);
            } catch {
                console.log("Not supported:", labels[i], candidates[i]);
            }
        }
        console.log("Total supported (by probing):", found);
    }

    // Helpers

    function _logNativeBalance(address a, string memory symbol) internal view {
        uint256 bal = a.balance;
        console.log(string.concat(symbol, " balance (wei):"), bal);
        console.log(
            string.concat(symbol, " balance (~6dp):"),
            _toFixed6(bal),
            symbol
        );
    }

    // Return a fixed-6 decimal string for a wei-based amount (1e18)
    function _toFixed6(
        uint256 weiAmount
    ) internal pure returns (string memory) {
        uint256 intPart = weiAmount / 1e18;
        uint256 frac6 = (weiAmount % 1e18) / 1e12; // 6 decimals
        return string.concat(_u2s(intPart), ".", _pad6(frac6));
    }

    // uint -> string
    function _u2s(uint256 v) internal pure returns (string memory str) {
        if (v == 0) return "0";
        uint256 j = v;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory b = new bytes(len);
        uint256 k = len;
        while (v != 0) {
            k -= 1;
            b[k] = bytes1(uint8(48 + (v % 10)));
            v /= 10;
        }
        str = string(b);
    }

    // zero-pad to 6 digits
    function _pad6(uint256 v) internal pure returns (string memory) {
        string memory s = _u2s(v);
        uint256 len = bytes(s).length;
        if (len >= 6) return s;
        bytes memory out = new bytes(6);
        uint256 pad = 6 - len;
        for (uint256 i = 0; i < pad; i++) out[i] = bytes1("0");
        for (uint256 i = 0; i < len; i++) out[pad + i] = bytes(s)[i];
        return string(out);
    }
}
