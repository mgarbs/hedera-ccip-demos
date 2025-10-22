// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

/**
 * @title WrapHBAR
 * @notice Wrap native HBAR to WHBAR on Hedera Testnet by calling WHBAR.deposit()
 * @dev Run:
 * forge script script/WrapHBAR.s.sol:WrapHBAR --rpc-url hedera_testnet --broadcast --sig "run(uint256)" 50
 * Requires PRIVATE_KEY in .env (hex 0x...).
 */
contract WrapHBAR is Script {
    address constant WHBAR = 0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed;

    // amountHBAR is whole HBAR units (e.g., 50 for 50 HBAR)
    function run(uint256 amountHBAR) external {
        // Read PRIVATE_KEY as hex (0x...) from env
        uint256 privateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        vm.startBroadcast(privateKey);

        uint256 value = amountHBAR * 1e18;
        (bool ok, ) = WHBAR.call{value: value}(
            abi.encodeWithSignature("deposit()")
        );
        require(ok, "WHBAR deposit failed");

        vm.stopBroadcast();
    }
}
