// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

/// @notice Minimal shared helpers for CCIP tests, kept intentionally simple.
contract CCIPTestBase is Test {
    // CCIP extra args for a 200k gas limit
    bytes constant EXTRA_ARGS =
        hex"97a657c90000000000000000000000000000000000000000000000000000000000030d40";

    /// @notice Return the 0x-private key from env (vm.envOr first, then bytes32 fallback).
    function _readPrivateKey() internal view returns (uint256 pk) {
        pk = vm.envOr("PRIVATE_KEY", uint256(0));
        if (pk == 0) {
            try vm.envBytes32("PRIVATE_KEY") returns (bytes32 b) {
                pk = uint256(b);
            } catch {}
        }
    }

    /// @notice Either derive the account from PRIVATE_KEY or make a local account.
    /// @return a The account address
    /// @return fromEnv True if derived from PRIVATE_KEY, false if local
    function _getTestAccount() internal returns (address a, bool fromEnv) {
        uint256 pk = _readPrivateKey();
        if (pk != 0) {
            return (vm.addr(pk), true);
        }
        return (makeAddr("localTestAccount"), false);
    }

    /// @notice Ensure the account has at least "required" native balance on the fork.
    function _ensureNativeAtLeast(
        address a,
        uint256 required,
        string memory symbol
    ) internal {
        uint256 bal = a.balance;
        if (bal < required) {
            vm.deal(a, required);
            console.log(
                string.concat("Topped up ", symbol, " on fork to cover fee.")
            );
            _logWeiAndApprox("New native balance", required, symbol);
        }
    }

    /// @notice One-liner to log the explorer URL consistently.
    function _logExplorer(bytes32 messageId) internal pure {
        console.log(
            string.concat(
                "CCIP Explorer: https://ccip.chain.link/msg/",
                vm.toString(messageId)
            )
        );
    }

    /// @notice Log an address header plus native balance.
    function _logAccountHeader(address a, string memory symbol) internal view {
        console.log("Using account:", a);
        _logWeiAndApprox(string.concat(symbol, " balance"), a.balance, symbol);
    }

    /// @notice Log "title (wei): X" and "title (~6dp): Y symbol".
    function _logWeiAndApprox(
        string memory title,
        uint256 weiAmount,
        string memory symbol
    ) internal pure {
        console.log(string.concat(title, " (wei):"), weiAmount);
        console.log(
            string.concat(title, " (~6dp): "),
            _toFixed6(weiAmount),
            string.concat(" ", symbol)
        );
    }

    /// @notice Return a fixed-6 decimal string for a wei-based amount (1e18).
    function _toFixed6(
        uint256 weiAmount
    ) internal pure returns (string memory) {
        uint256 intPart = weiAmount / 1e18;
        uint256 frac6 = (weiAmount % 1e18) / 1e12; // 6 decimals
        return string.concat(_u2s(intPart), ".", _pad6(frac6));
    }

    // --- tiny string helpers ---

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
