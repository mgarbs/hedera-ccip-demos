// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ICCIPRouter} from "../src/ICCIPRouter.sol";
import {IERC20} from "../src/IERC20.sol";
import {CCIPTestBase} from "./utils/CCIPTestBase.sol";

/**
 * @title HederaCCIPTest
 * @notice Foundry fork tests (Hedera -> Sepolia). Reads real chain state; does NOT broadcast.
 * @dev Simple, self-explanatory logs; minimal helpers shared via CCIPTestBase.
 */
contract HederaCCIPTest is CCIPTestBase {
    // Hedera Router + tokens
    ICCIPRouter constant HEDERA_ROUTER =
        ICCIPRouter(0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4);
    IERC20 constant LINK = IERC20(0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6);
    IERC20 constant WHBAR = IERC20(0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed);

    // Sepolia chain selector (destination)
    uint64 constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;

    // Test account
    address testAccount;

    function setUp() public {
        // Run on a Hedera Testnet fork; local state changes won't hit the real network
        vm.createSelectFork("hedera_testnet");
        (testAccount, ) = _getTestAccount();

        console.log("=== Setup: Hedera Testnet fork ===");
        console.log("Router:", address(HEDERA_ROUTER));
        console.log("Dest chain selector:", SEPOLIA_CHAIN_SELECTOR);
        _logAccountHeader(testAccount, "HBAR");
    }

    /// @notice Enumerate supported fee tokens by probing getFee for known candidates.
    function test_EnumerateSupportedFeeTokens() public view {
        console.log(
            "\n=== Enumerate supported fee tokens (Hedera -> Sepolia) ==="
        );
        address[3] memory candidates = [
            address(0),
            address(LINK),
            address(WHBAR)
        ];
        string[3] memory labels = ["HBAR(native)", "LINK", "WHBAR"];

        bytes memory receiver = abi.encode(testAccount);
        string memory probeMsg = "probe";

        uint256 supported = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            ICCIPRouter.EVM2AnyMessage memory m = ICCIPRouter.EVM2AnyMessage({
                receiver: receiver,
                data: abi.encode(probeMsg),
                tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
                feeToken: candidates[i],
                extraArgs: EXTRA_ARGS
            });

            try HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, m) returns (
                uint256 /*fee*/
            ) {
                supported++;
                console.log("Supported:", labels[i], candidates[i]);
            } catch {
                console.log("Not supported:", labels[i], candidates[i]);
            }
        }
        console.log("Total supported:", supported);
    }

    /// @notice Native HBAR payment; asserts delta == fee (gas set to 0).
    function test_SendMessageWithNativeHBAR() public {
        console.log("\n=== Send CCIP with native HBAR (Hedera -> Sepolia) ===");

        bytes memory receiver = abi.encode(testAccount);
        ICCIPRouter.EVM2AnyMessage memory msg_ = ICCIPRouter.EVM2AnyMessage({
            receiver: receiver,
            data: abi.encode(
                "Hello from Hedera via CCIP, paid with native HBAR!"
            ),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: EXTRA_ARGS
        });

        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, msg_);
        _logWeiAndApprox("CCIP fee", fee, "HBAR");

        _ensureNativeAtLeast(testAccount, fee, "HBAR");

        uint256 start = testAccount.balance;
        _logWeiAndApprox("Starting HBAR", start, "HBAR");

        vm.txGasPrice(0);
        vm.prank(testAccount);
        bytes32 messageId = HEDERA_ROUTER.ccipSend{value: fee}(
            SEPOLIA_CHAIN_SELECTOR,
            msg_
        );

        uint256 end = testAccount.balance;
        _logWeiAndApprox("Ending HBAR", end, "HBAR");

        uint256 delta = start - end;
        _logWeiAndApprox("Balance delta", delta, "HBAR");
        assertEq(delta, fee, "Native HBAR delta should equal CCIP fee (gas=0)");

        _logExplorer(messageId);
        console.log("OK: Native HBAR payment");
    }

    /// @notice WHBAR payment (8 decimals); requires WHBAR balance on fork (otherwise skip).
    function test_SendMessageWithWHBAR() public {
        console.log("\n=== Send CCIP with WHBAR (Hedera -> Sepolia) ===");

        uint256 whbarBal = WHBAR.balanceOf(testAccount);
        console.log("WHBAR balance (raw):", whbarBal);

        bytes memory receiver = abi.encode(testAccount);
        ICCIPRouter.EVM2AnyMessage memory msg_ = ICCIPRouter.EVM2AnyMessage({
            receiver: receiver,
            data: abi.encode("Hello from Hedera via CCIP, paid with WHBAR!"),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(WHBAR),
            extraArgs: EXTRA_ARGS
        });

        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, msg_);
        console.log("WHBAR fee (raw):", fee);

        if (whbarBal < fee) {
            console.log(
                "Skipping: insufficient WHBAR on fork. See README for wrapping instructions."
            );
            return;
        }

        uint256 start = WHBAR.balanceOf(testAccount);
        vm.prank(testAccount);
        WHBAR.approve(address(HEDERA_ROUTER), fee);

        vm.prank(testAccount);
        bytes32 messageId = HEDERA_ROUTER.ccipSend(
            SEPOLIA_CHAIN_SELECTOR,
            msg_
        );

        uint256 end = WHBAR.balanceOf(testAccount);
        uint256 delta = start - end;
        console.log("WHBAR delta (raw):", delta);
        assertEq(delta, fee, "WHBAR delta should equal CCIP fee");

        _logExplorer(messageId);
        console.log("OK: WHBAR payment");
    }

    /// @notice LINK payment; requires LINK balance on fork (otherwise skip).
    function test_SendMessageWithLINK() public {
        console.log("\n=== Send CCIP with LINK (Hedera -> Sepolia) ===");

        uint256 linkBal = LINK.balanceOf(testAccount);
        console.log("LINK balance (raw):", linkBal);

        bytes memory receiver = abi.encode(testAccount);
        ICCIPRouter.EVM2AnyMessage memory msg_ = ICCIPRouter.EVM2AnyMessage({
            receiver: receiver,
            data: abi.encode("Hello from Hedera via CCIP, paid with LINK!"),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(LINK),
            extraArgs: EXTRA_ARGS
        });

        uint256 fee = HEDERA_ROUTER.getFee(SEPOLIA_CHAIN_SELECTOR, msg_);
        console.log("LINK fee (raw):", fee);

        if (linkBal < fee) {
            console.log(
                "Skipping: insufficient LINK on fork. Get testnet LINK at https://faucets.chain.link/hedera-testnet"
            );
            return;
        }

        uint256 start = LINK.balanceOf(testAccount);
        vm.prank(testAccount);
        LINK.approve(address(HEDERA_ROUTER), fee);

        vm.prank(testAccount);
        bytes32 messageId = HEDERA_ROUTER.ccipSend(
            SEPOLIA_CHAIN_SELECTOR,
            msg_
        );

        uint256 end = LINK.balanceOf(testAccount);
        uint256 delta = start - end;
        console.log("LINK delta (raw):", delta);
        assertEq(delta, fee, "LINK delta should equal CCIP fee");

        _logExplorer(messageId);
        console.log("OK: LINK payment");
    }
}
