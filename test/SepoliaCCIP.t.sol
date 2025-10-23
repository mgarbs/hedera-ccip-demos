// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ICCIPRouter} from "../src/ICCIPRouter.sol";
import {IERC20} from "../src/IERC20.sol";
import {CCIPTestBase} from "./utils/CCIPTestBase.sol";

/**
 * @title SepoliaCCIPTest
 * @notice Foundry fork tests (Sepolia -> Hedera). Reads real chain state; does NOT broadcast.
 * @dev Simple, self-explanatory logs; minimal helpers shared via CCIPTestBase.
 */
contract SepoliaCCIPTest is CCIPTestBase {
    // Sepolia Router + LINK (canonical CCIP test addresses)
    ICCIPRouter constant SEPOLIA_ROUTER =
        ICCIPRouter(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);
    IERC20 constant LINK = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    // Hedera chain selector (destination)
    uint64 constant HEDERA_CHAIN_SELECTOR = 222782988166878823;

    // Test account
    address testAccount;

    function setUp() public {
        // Run on a Sepolia fork; local state changes won't hit the real network
        vm.createSelectFork("sepolia");
        (testAccount, ) = _getTestAccount();

        console.log("=== Setup: Sepolia fork ===");
        console.log("Router:", address(SEPOLIA_ROUTER));
        console.log("Dest chain selector:", HEDERA_CHAIN_SELECTOR);
        _logAccountHeader(testAccount, "ETH");
    }

    /// @notice Enumerate supported fee tokens by probing getFee for known candidates.
    function test_EnumerateSupportedFeeTokens() public view {
        console.log(
            "\n=== Enumerate supported fee tokens (Sepolia -> Hedera) ==="
        );
        address[2] memory candidates = [address(0), address(LINK)];
        string[2] memory labels = ["ETH(native)", "LINK"];

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

            try SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, m) returns (
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

    /// @notice Native ETH payment; asserts delta == fee (gas set to 0).
    function test_SendMessageWithNativeETH() public {
        console.log("\n=== Send CCIP with native ETH (Sepolia -> Hedera) ===");

        bytes memory receiver = abi.encode(testAccount);
        ICCIPRouter.EVM2AnyMessage memory msg_ = ICCIPRouter.EVM2AnyMessage({
            receiver: receiver,
            data: abi.encode(
                "Hello from Sepolia via CCIP, paid with native ETH!"
            ),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: EXTRA_ARGS
        });

        uint256 fee = SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, msg_);
        _logWeiAndApprox("CCIP fee", fee, "ETH");

        _ensureNativeAtLeast(testAccount, fee, "ETH");

        uint256 start = testAccount.balance;
        _logWeiAndApprox("Starting ETH", start, "ETH");

        vm.txGasPrice(0);
        vm.prank(testAccount);
        bytes32 messageId = SEPOLIA_ROUTER.ccipSend{value: fee}(
            HEDERA_CHAIN_SELECTOR,
            msg_
        );

        uint256 end = testAccount.balance;
        _logWeiAndApprox("Ending ETH", end, "ETH");

        uint256 delta = start - end;
        _logWeiAndApprox("Balance delta", delta, "ETH");
        assertEq(delta, fee, "Native ETH delta should equal CCIP fee (gas=0)");

        _logExplorer(messageId);
        console.log("OK: Native ETH payment");
    }

    /// @notice LINK payment; requires sufficient LINK on fork (otherwise skip with guidance).
    function test_SendMessageWithLINK() public {
        console.log("\n=== Send CCIP with LINK (Sepolia -> Hedera) ===");

        uint256 linkBal = LINK.balanceOf(testAccount);
        console.log("LINK balance (raw):", linkBal);

        bytes memory receiver = abi.encode(testAccount);
        ICCIPRouter.EVM2AnyMessage memory msg_ = ICCIPRouter.EVM2AnyMessage({
            receiver: receiver,
            data: abi.encode("Hello from Sepolia via CCIP, paid with LINK!"),
            tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
            feeToken: address(LINK),
            extraArgs: EXTRA_ARGS
        });

        uint256 fee = SEPOLIA_ROUTER.getFee(HEDERA_CHAIN_SELECTOR, msg_);
        console.log("LINK fee (raw):", fee);

        if (linkBal < fee) {
            console.log(
                "Skipping: insufficient LINK on fork. Get testnet LINK at https://faucets.chain.link/sepolia"
            );
            return;
        }

        uint256 start = LINK.balanceOf(testAccount);
        vm.prank(testAccount);
        LINK.approve(address(SEPOLIA_ROUTER), fee);

        vm.prank(testAccount);
        bytes32 messageId = SEPOLIA_ROUTER.ccipSend(
            HEDERA_CHAIN_SELECTOR,
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
