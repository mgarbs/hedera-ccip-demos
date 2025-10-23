// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {CCIPSender} from "../../src/CCIPSender.sol";
import {CCIPMessageReceiver} from "../../src/CCIPReceiver.sol";

/**
 * @title CCIPTestBase
 * @notice Base contract for CCIP tests with common setup and utilities
 */
contract CCIPTestBase is Test {
    // Hedera Testnet - Updated 2025
    address constant HEDERA_ROUTER = 0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4;
    address constant HEDERA_LINK = 0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6;
    address constant HEDERA_WHBAR = 0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed;
    uint64 constant HEDERA_CHAIN_SELECTOR = 222782988166878823;

    // Sepolia Testnet
    address constant SEPOLIA_ROUTER = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address constant SEPOLIA_LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    uint64 constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;

    // Test accounts
    address public alice;
    address public bob;

    // Contracts
    CCIPSender public sender;
    CCIPMessageReceiver public receiver;

    function setUp() public virtual {
        // Create test accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Fund test accounts
        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
    }

    /// @notice Helper to deal ERC20 tokens
    function dealToken(address token, address to, uint256 amount) internal {
        deal(token, to, amount);
    }

    /// @notice Helper to approve tokens
    function approveToken(address token, address spender, uint256 amount) internal {
        (bool success,) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", spender, amount)
        );
        require(success, "Token approval failed");
    }
}
