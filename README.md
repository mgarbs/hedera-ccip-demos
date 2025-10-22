# Hedera CCIP Demos

Foundry-based tests demonstrating bi-directional cross-chain messaging between Hedera Testnet and Ethereum Sepolia using Chainlink's Cross-Chain Interoperability Protocol (CCIP), with clear logging and balance tracking for fee payments.

This repo uses a local Foundry EVM fork of real networks (Hedera Testnet, Ethereum Sepolia). Tests read real on-chain state at the forked block but do NOT broadcast real transactions.

## How the tests work

- Execution model:

  - Tests run on a local Foundry fork (Hedera Testnet or Sepolia).
  - Reads (balances, router config, token state) come from real chain state at the forked point.
  - Writes (approvals, ccipSend, native transfers) affect only the local fork. They are not sent to live networks.

- Accounts and funding:

  - If `.env` contains `PRIVATE_KEY=0x...`, tests derive the address and run with that account (read-only state from fork; no real txs).
  - If no `PRIVATE_KEY` is provided, tests use a local account on the fork.
  - Native tokens: tests auto top-up native balance on the fork if needed to cover CCIP fees (so they “just work”).
  - ERC-20 tokens: you must have testnet balances at your address in the forked state, otherwise those tests are skipped (with guidance).

- Fees and balance tracking:

  - Each payment test:
    - Queries `getFee` on the CCIP Router for the given destination and fee token.
    - Records starting balance (native or token).
    - Executes `ccipSend` (with `value: fee` for native, or `approve + ccipSend` for tokens).
    - Records ending balance and asserts the delta equals the fee.
  - For native payments, tests set `vm.txGasPrice(0)` so the native balance delta equals the CCIP fee exactly (no gas spent in tests).
  - Logs print both wei and approximate 6-decimal units to avoid “0” confusion on small amounts.

- CCIP Explorer links:
  - Tests print a CCIP Explorer URL with the messageId for convenience, e.g.:
    - `https://ccip.chain.link/msg/0x...`
  - Because tests run on a local fork and do not broadcast, these messageIds will not appear in the Explorer. Use these URLs only when sending real transactions on live networks.

## Caveats: getSupportedTokens removed

Recent CCIP router versions removed `getSupportedTokens(uint64)`. Calling it reverts with a custom error like:

- `GetSupportedTokensFunctionalityRemovedCheckAdminRegistry()`

Instead of enumerating fee tokens via the router, the recommended approach is to probe for support:

- Build a CCIP message with your candidate fee token in `feeToken`.
- Call `getFee(destinationChainSelector, message)`.
  - If it returns a value, that fee token is supported for that lane.
  - If it reverts, the token is not supported/configured for that lane.

This repo includes enumeration tests that use this probing method and log which tokens are supported.

## Installation

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install
```

## Configuration

Copy the example environment file and set your private key:

```bash
cp .env.example .env
```

Edit `.env`:

```
PRIVATE_KEY=0x...
```

Notes:

- Hex with `0x` prefix is supported.
- Foundry automatically reads `.env` from the project root.

## Running tests

General:

- Use `-vvv` for detailed logs.
- All tests run against local forks of the target networks and do not broadcast.

### Sepolia → Hedera

```bash
# Enumerate supported fee tokens by probing (ETH, LINK)
forge test --match-contract SepoliaCCIPTest --match-test test_EnumerateSupportedFeeTokens -vvv

# Native ETH payment with balance tracking (gas=0 in test so delta == fee)
forge test --match-contract SepoliaCCIPTest --match-test test_SendMessageWithNativeETH -vvv

# LINK payment with balance tracking (requires LINK on Sepolia)
forge test --match-contract SepoliaCCIPTest --match-test test_SendMessageWithLINK -vvv
```

### Hedera → Sepolia

```bash
# Enumerate supported fee tokens by probing (HBAR, LINK, WHBAR)
forge test --match-contract HederaCCIPTest --match-test test_EnumerateSupportedFeeTokens -vvv

# Native HBAR payment with balance tracking (gas=0 in test so delta == fee)
forge test --match-contract HederaCCIPTest --match-test test_SendMessageWithNativeHBAR -vvv

# WHBAR payment with balance tracking (requires WHBAR on Hedera)
forge test --match-contract HederaCCIPTest --match-test test_SendMessageWithWHBAR -vvv

# LINK payment with balance tracking (requires LINK on Hedera)
forge test --match-contract HederaCCIPTest --match-test test_SendMessageWithLINK -vvv
```

## Wrap HBAR to WHBAR (Hedera Testnet)

You have two options:

1. Foundry script (recommended)

```bash
# Wrap 50 HBAR to WHBAR (uses PRIVATE_KEY from .env)
forge script script/WrapHBAR.s.sol:WrapHBAR \
  --rpc-url hedera_testnet \
  --broadcast \
  --sig "run(uint256)" 50
```

2. One-liner with cast

```bash
# Wrap 50 HBAR to WHBAR
cast send 0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed "deposit()" \
  --value 50000000000000000000 \
  --rpc-url https://testnet.hashio.io/api \
  --private-key $PRIVATE_KEY
```

WHBAR uses 8 decimals (unlike most ERC-20s with 18). Tests log raw amounts for clarity.

## Network details

- Execution environment: Foundry forks (see RPCs in `foundry.toml`)

  - Hedera Testnet RPC: `https://testnet.hashio.io/api`
  - Sepolia RPC: `https://ethereum-sepolia-rpc.publicnode.com`

- CCIP Routers and Chain Selectors:

  - Hedera Testnet
    - Router: `0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4`
    - Chain Selector: `222782988166878823`
  - Ethereum Sepolia
    - Router: `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
    - Chain Selector: `16015286601757825753`

- Token addresses
  - Hedera Testnet:
    - LINK: `0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6`
    - WHBAR: `0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed`
  - Ethereum Sepolia:
    - LINK: `0x779877A7B0D9E8603169DdbD7836e478b4624789`

## Getting testnet funds

- Hedera HBAR: https://portal.hedera.com/faucet
- Hedera LINK: https://faucets.chain.link/hedera-testnet
- Sepolia ETH: https://faucets.chain.link/sepolia

## Repo layout (tests)

- `test/utils/CCIPTestBase.sol`: small shared helpers for env key, logging, native top-up, explorer URL.
- `test/SepoliaCCIP.t.sol`: Sepolia → Hedera tests (enumeration, native ETH, LINK).
- `test/HederaCCIP.t.sol`: Hedera → Sepolia tests (enumeration, native HBAR, WHBAR, LINK).

## Notes

- Because tests run on forks, CCIP messageIds printed in logs are for reference only and will not appear in CCIP Explorer.
- Native delta equals fee in tests because we set `txGasPrice(0)`. This is only for test determinism on forks.
- The enumeration tests implement the recommended “probe with getFee” approach in place of the removed `getSupportedTokens`.

## License

MIT
