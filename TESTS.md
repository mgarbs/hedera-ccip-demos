# Foundry Tests for Hedera CCIP

This document explains the Foundry test suite for demonstrating CCIP cross-chain messaging with proper balance tracking.

## Background

The Chainlink team recommended using Foundry (or Hardhat) to properly demonstrate native token payments in CCIP. The key requirement is to:

1. Store the wallet's starting balance
2. Execute the CCIP transaction
3. Store the wallet's ending balance
4. Assert that `startingBalance - endingBalance == fee`

This pattern definitively proves that native tokens (HBAR/ETH) are being deducted from the wallet, not just wrapped versions.

## Test Architecture

### Contracts

#### Interfaces (`src/`)

- **ICCIPRouter.sol** - Interface for Chainlink CCIP Router
  - `ccipSend()` - Send cross-chain messages
  - `getFee()` - Calculate exact fee required
  - `getSupportedTokens()` - Query supported fee tokens

- **IERC20.sol** - Standard ERC20 interface for LINK and WHBAR tokens
  - `balanceOf()` - Check token balance
  - `approve()` - Approve router to spend tokens
  - `allowance()` - Check current approval amount

#### Test Contracts (`test/`)

- **HederaCCIPTest.t.sol** - Tests for Hedera Testnet → Ethereum Sepolia
  - `test_SendMessageWithNativeHBAR()` - Native HBAR payment with balance tracking
  - `test_SendMessageWithWHBAR()` - WHBAR (8 decimals) payment with balance tracking
  - `test_SendMessageWithLINK()` - LINK (18 decimals) payment with balance tracking
  - `test_CompareFees()` - Compare fees across all payment methods

- **SepoliaCCIPTest.t.sol** - Tests for Ethereum Sepolia → Hedera Testnet
  - `test_SendMessageWithNativeETH()` - Native ETH payment with balance tracking
  - `test_SendMessageWithLINK()` - LINK payment with balance tracking
  - `test_CompareFees()` - Compare ETH vs LINK fees

## How Balance Tracking Works

### Native Token Payment (HBAR/ETH)

```solidity
// 1. Record starting balance
uint256 startingBalance = testAccount.balance;

// 2. Get the exact fee
uint256 fee = ROUTER.getFee(chainSelector, message);

// 3. Send CCIP message with native payment
ROUTER.ccipSend{value: fee}(chainSelector, message);

// 4. Record ending balance
uint256 endingBalance = testAccount.balance;

// 5. Assert balance difference equals fee
assertEq(startingBalance - endingBalance, fee);
```

### ERC20 Token Payment (WHBAR/LINK)

```solidity
// 1. Record starting token balance
uint256 startingBalance = TOKEN.balanceOf(testAccount);

// 2. Get the exact fee in tokens
uint256 fee = ROUTER.getFee(chainSelector, message);

// 3. Approve router to spend tokens
TOKEN.approve(address(ROUTER), fee);

// 4. Send CCIP message with token payment
ROUTER.ccipSend(chainSelector, message);

// 5. Record ending token balance
uint256 endingBalance = TOKEN.balanceOf(testAccount);

// 6. Assert balance difference equals fee
assertEq(startingBalance - endingBalance, fee);
```

## Running Tests

### Prerequisites

1. **Install Foundry**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Set up environment**:
   ```bash
   cp .env.example .env
   # Edit .env and add your PRIVATE_KEY
   ```

3. **Ensure you have testnet funds**:
   - HBAR: https://portal.hedera.com/faucet
   - LINK (Hedera): https://faucets.chain.link/hedera-testnet
   - ETH (Sepolia): https://faucets.chain.link/sepolia

### Build

```bash
forge build
```

### Run All Tests

```bash
# All Hedera tests
forge test --match-contract HederaCCIPTest -vvv

# All Sepolia tests
forge test --match-contract SepoliaCCIPTest -vvv

# Everything
forge test -vvv
```

### Run Specific Tests

```bash
# Native HBAR payment
forge test --match-test test_SendMessageWithNativeHBAR -vvv

# WHBAR payment
forge test --match-test test_SendMessageWithWHBAR -vvv

# LINK payment (Hedera)
forge test --match-test test_SendMessageWithLINK --match-contract HederaCCIPTest -vvv

# Native ETH payment
forge test --match-test test_SendMessageWithNativeETH -vvv

# Fee comparison
forge test --match-test test_CompareFees -vvv
```

### Verbosity Levels

- `-v` - Show test names
- `-vv` - Show test names and results
- `-vvv` - Show test names, results, and console.log output (recommended)
- `-vvvv` - Show test names, results, console.log, and stack traces

## Test Output

Each test provides detailed output:

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
✅ Native HBAR payment successful!
```

## Key Differences: Native vs Wrapped Tokens

### Native HBAR/ETH
- Paid directly from wallet balance
- No token approval required
- Uses `{value: fee}` in transaction
- `feeToken: address(0)` in CCIP message

### WHBAR (Wrapped HBAR)
- ERC20 token with 8 decimals (unusual!)
- Requires `approve()` before payment
- Paid from token balance, not native balance
- `feeToken: address(WHBAR)` in CCIP message

### LINK Token
- Standard ERC20 with 18 decimals
- Requires `approve()` before payment
- Available on both Hedera and Sepolia
- `feeToken: address(LINK)` in CCIP message

## Forking

The tests use Foundry's forking feature to interact with live testnet contracts:

```toml
# foundry.toml
[rpc_endpoints]
hedera_testnet = "https://testnet.hashio.io/api"
sepolia = "https://ethereum-sepolia-rpc.publicnode.com"
```

Tests automatically fork the appropriate network in `setUp()`:

```solidity
function setUp() public {
    vm.createSelectFork("hedera_testnet");
    // ... setup code
}
```

## Troubleshooting

### "Insufficient balance" errors

Make sure you have enough testnet tokens:
- Get HBAR: https://portal.hedera.com/faucet
- Get LINK (Hedera): https://faucets.chain.link/hedera-testnet
- Get ETH (Sepolia): https://faucets.chain.link/sepolia

### WHBAR tests skipped

You need to wrap HBAR first:
```bash
pnpm run wrap-hbar
```

### RPC connection issues

The tests use public RPC endpoints. If you encounter rate limits:
1. Wait a few minutes and try again
2. Use a private RPC endpoint in `foundry.toml`

### Private key not found

Set your private key in `.env`:
```
PRIVATE_KEY=0x...
```

If not set, tests will use a generated test account with mock funds (only works in fork mode).

## Gas Optimization

To analyze gas usage:

```bash
# Generate gas snapshot
forge snapshot

# Compare gas changes
forge snapshot --diff
```

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Foundry Tests
  run: |
    forge test --match-contract HederaCCIPTest -vvv
```

For automated testing without real funds, consider:
1. Using mocked contracts in a local fork
2. Running read-only tests (like fee comparisons)
3. Setting up a dedicated testnet wallet with auto-replenishment

## Resources

- Chainlink CCIP Documentation: https://docs.chain.link/ccip
- Foundry Book: https://book.getfoundry.sh/
- Hedera Testnet: https://portal.hedera.com/
- CCIP Explorer: https://ccip.chain.link/
