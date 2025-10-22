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
    ICCIPRouter constant SEPOLIA_ROUTER =
        ICCIPRouter(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);
    IERC20 constant LINK = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    // Hedera Chain Selector
    uint64 constant HEDERA_CHAIN_SELECTOR = 222782988166878823;

    // Test account
    address testAccount;

    // CCIP extra args for 200k gas limit
    bytes extraArgs =
        hex"97a657c90000000000000000000000000000000000000000000000000000000000030d40";

    function setUp() public {
        // Fork Sepolia
        vm.createSelectFork("sepolia");

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
            // Fund the account with 1 ETH (local fork funding)
            vm.deal(testAccount, 1 ether);
        }

        console.log("Testing with account:", testAccount);
        _logNativeBalance(testAccount, "ETH");
    }

    /**
     * @notice Test sending a CCIP message paying with native ETH
     * @dev For native tests, set gas price to 0 so balance delta equals fee exactly.
     */
    function test_SendMessageWithNativeETH() public {
        console.log("\n=== Test: Send CCIP Message with Native ETH ===");

        // Prepare the CCIP message
        string
            memory message = "Hello from Sepolia via CCIP, paid with native ETH!";
        bytes memory encodedReceiver = abi.encode(testAccount);

        ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter
            .EVM2AnyMessage({
                receiver: encodedReceiver,
                data: abi.encode(message),
                tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
                feeToken: address(0), // address(0) indicates native token payment
                extraArgs: extraArgs
            });

        // Get the fee required for native ETH payment
        uint256 fee = SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, ccipMessage);
        console.log("CCIP fee (ETH, wei):", fee);
        console.log("CCIP fee (~6dp):", _toFixed6(fee), "ETH");

        // Record starting balance
        uint256 startingBalance = testAccount.balance;
        console.log("Starting ETH balance (wei):", startingBalance);
        console.log(
            "Starting ETH balance (~6dp):",
            _toFixed6(startingBalance),
            "ETH"
        );

        // Verify we have enough balance
        require(startingBalance >= fee, "Insufficient ETH balance for fee");

        // Ensure gas doesn't skew native balance delta
        vm.txGasPrice(0);

        // Send the CCIP message with native ETH payment
        vm.prank(testAccount);
        bytes32 messageId = SEPOLIA_ROUTER.ccipSend{value: fee}(
            HEDERA_CHAIN_SELECTOR,
            ccipMessage
        );

        // Record ending balance
        uint256 endingBalance = testAccount.balance;
        console.log("Ending ETH balance (wei):", endingBalance);
        console.log(
            "Ending ETH balance (~6dp):",
            _toFixed6(endingBalance),
            "ETH"
        );

        // Calculate the actual amount spent
        uint256 balanceDifference = startingBalance - endingBalance;
        console.log("Balance difference (wei):", balanceDifference);
        console.log(
            "Balance difference (~6dp):",
            _toFixed6(balanceDifference),
            "ETH"
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
        console.log("\nNative ETH payment successful!");
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
            console.log("Get LINK from: https://faucets.chain.link/sepolia");
            return;
        }

        // Prepare the CCIP message
        string memory message = "Hello from Sepolia via CCIP, paid with LINK!";
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
        uint256 fee = SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, ccipMessage);
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
        LINK.approve(address(SEPOLIA_ROUTER), fee);

        // Send the CCIP message with LINK payment
        vm.prank(testAccount);
        bytes32 messageId = SEPOLIA_ROUTER.ccipSend(
            HEDERA_CHAIN_SELECTOR,
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
     * @notice Explicit probing-only test to enumerate supported tokens on the Sepolia -> Hedera lane.
     */
    function test_ListSupportedFeeTokensByProbing() public view {
        console.log(
            "\n=== Enumerating supported fee tokens by probing (Sepolia -> Hedera) ==="
        );
        address[] memory candidates = new address[](2);
        string[] memory labels = new string[](2);
        candidates[0] = address(0);
        labels[0] = "ETH(native)";
        candidates[1] = address(LINK);
        labels[1] = "LINK";

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
            try SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, m) returns (
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
