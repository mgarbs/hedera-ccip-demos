# Foundry Implementation Summary

This branch (`foundry-ccip-tests`) implements Foundry-based tests for Hedera CCIP as recommended by the Chainlink team.

## What Was Added

### Core Changes

1. **Foundry Project Structure**
   - Initialized Foundry with `forge init`
   - Configured `foundry.toml` with Hedera and Sepolia RPC endpoints
   - Set up proper Solidity version (0.8.28) and EVM version (cancun)

2. **Smart Contract Interfaces** (`src/`)
   - `ICCIPRouter.sol` - CCIP Router interface with `ccipSend()`, `getFee()`, and `getSupportedTokens()`
   - `IERC20.sol` - Standard ERC20 interface for LINK and WHBAR tokens

3. **Test Contracts** (`test/`)
   - `HederaCCIP.t.sol` - Tests for Hedera → Sepolia with native HBAR, WHBAR, and LINK
   - `SepoliaCCIP.t.sol` - Tests for Sepolia → Hedera with native ETH and LINK

4. **Documentation**
   - Updated `README.md` with comprehensive Foundry instructions
   - Created `TESTS.md` with detailed testing methodology
   - Created this summary document

### Key Features

Each test implements the **balance tracking pattern** recommended by Chainlink:

```solidity
// 1. Record starting balance
uint256 startingBalance = testAccount.balance;

// 2. Get fee and execute transaction
uint256 fee = ROUTER.getFee(...);
ROUTER.ccipSend{value: fee}(...);

// 3. Record ending balance
uint256 endingBalance = testAccount.balance;

// 4. Assert balance difference equals fee
assertEq(startingBalance - endingBalance, fee);
```

This definitively proves native HBAR/ETH is being used, not just wrapped versions.

## How to Test

### 1. Environment Setup

Make sure your `.env` has your private key:
```bash
PRIVATE_KEY=0x...
```

### 2. Build

```bash
forge build
```

Should output:
```
Compiler run successful!
```

### 3. Run Tests

#### Test Native HBAR Payment (Hedera → Sepolia)
```bash
forge test --match-test test_SendMessageWithNativeHBAR -vvv
```

This is the **key test** that demonstrates native HBAR usage with balance tracking.

#### Test WHBAR Payment (Hedera → Sepolia)
```bash
forge test --match-test test_SendMessageWithWHBAR -vvv
```

Note: Requires WHBAR. If you don't have it, run `pnpm run wrap-hbar` first.

#### Test LINK Payment (Hedera → Sepolia)
```bash
forge test --match-test test_SendMessageWithLINK --match-contract HederaCCIPTest -vvv
```

Note: Requires LINK from https://faucets.chain.link/hedera-testnet

#### Test Native ETH Payment (Sepolia → Hedera)
```bash
forge test --match-test test_SendMessageWithNativeETH -vvv
```

Note: Requires Sepolia ETH from https://faucets.chain.link/sepolia

#### Compare All Fees
```bash
forge test --match-test test_CompareFees -vvv
```

Shows fee differences between native/WHBAR/LINK on Hedera and native/LINK on Sepolia.

### 4. Run All Tests
```bash
# All Hedera tests
forge test --match-contract HederaCCIPTest -vvv

# All Sepolia tests
forge test --match-contract SepoliaCCIPTest -vvv

# Everything
forge test -vvv
```

## Expected Output

Each test shows:
- Account address being used
- Starting balance
- CCIP fee calculated
- Transaction execution
- Ending balance
- **Balance difference verification**
- Message ID for CCIP Explorer
- Success confirmation

Example:
```
=== Test: Send CCIP Message with Native HBAR ===
Testing with account: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
HBAR balance: 10 HBAR
CCIP fee (native HBAR): 0.5 HBAR
Starting HBAR balance: 10 HBAR
Ending HBAR balance: 9.5 HBAR
Balance difference: 0.5 HBAR
Message ID: 0x...
CCIP Explorer: https://ccip.chain.link/msg/0x...

Native HBAR payment successful!
```

## Files Changed/Added

### New Files
- `foundry.toml` - Foundry configuration
- `foundry.lock` - Dependency lock file
- `src/ICCIPRouter.sol` - CCIP Router interface
- `src/IERC20.sol` - ERC20 token interface
- `test/HederaCCIP.t.sol` - Hedera → Sepolia tests
- `test/SepoliaCCIP.t.sol` - Sepolia → Hedera tests
- `TESTS.md` - Detailed testing documentation
- `FOUNDRY_SETUP.md` - This file
- `lib/forge-std/` - Foundry standard library (submodule)
- `.github/workflows/` - GitHub Actions config (from Foundry init)

### Modified Files
- `README.md` - Updated with Foundry instructions
- `.gitmodules` - Added forge-std submodule

### Removed Files
- `src/Counter.sol` - Default Foundry template (removed)
- `test/Counter.t.sol` - Default Foundry template (removed)
- `script/Counter.s.sol` - Default Foundry template (removed)

## Differences from TypeScript Demos

### TypeScript Demos
- Use `@chainlink/ccip-js` SDK
- Interactive, one-time execution
- No automated balance verification
- Good for exploration and demos

### Foundry Tests
- Use direct contract calls via interfaces
- Automated, repeatable test suite
- **Proper balance tracking and assertions**
- Production-grade verification
- CI/CD ready

## What This Proves

The Foundry tests address the Chainlink team's feedback by:

1. **Proving Native Token Usage**
   - Tests record actual wallet balance before/after
   - Assert that `balanceDiff == fee`
   - This **proves** native HBAR/ETH is deducted, not just wrapped tokens

2. **Demonstrating All Payment Methods**
   - Native HBAR (with balance tracking) ✓
   - Wrapped HBAR / WHBAR (8 decimals) ✓
   - LINK token (18 decimals) ✓
   - Native ETH (with balance tracking) ✓

3. **Production-Grade Testing**
   - Follows Foundry best practices
   - Uses proper assertions
   - Handles edge cases (insufficient balance)
   - Provides detailed output

## Next Steps

1. **Validate Locally**
   - Run the tests with your own wallet
   - Verify balance tracking works as expected
   - Check message IDs on CCIP Explorer

2. **Review Code**
   - Examine test contracts in `test/`
   - Review interfaces in `src/`
   - Check documentation in `README.md` and `TESTS.md`

3. **When Ready, Create PR**
   - This branch is ready to merge when you validate it works
   - All tests compile successfully
   - Documentation is comprehensive

## Questions or Issues?

### Tests Skip Due to Insufficient Balance

This is expected behavior. Get testnet funds:
- HBAR: https://portal.hedera.com/faucet
- LINK (Hedera): https://faucets.chain.link/hedera-testnet
- ETH (Sepolia): https://faucets.chain.link/sepolia

### Want to See Raw Transaction Data?

Use `-vvvv` (4 v's) for maximum verbosity:
```bash
forge test --match-test test_SendMessageWithNativeHBAR -vvvv
```

### Need to Update RPC Endpoints?

Edit `foundry.toml`:
```toml
[rpc_endpoints]
hedera_testnet = "your-rpc-url"
sepolia = "your-rpc-url"
```

## Summary

This implementation provides exactly what the Chainlink team requested:
- **Hardhat/Foundry-based tests** (we chose Foundry) ✓
- **Balance tracking pattern** (startingBalance - endingBalance == fee) ✓
- **Demonstrates native HBAR** (not just WHBAR) ✓
- **Shows all payment methods** (native HBAR, WHBAR, LINK, native ETH) ✓

The tests are ready for validation and can be merged when you confirm they work as expected!
