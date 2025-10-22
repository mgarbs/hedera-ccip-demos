# Hedera CCIP Demos

Foundry-based tests demonstrating bi-directional cross-chain messaging between Hedera Testnet and Ethereum Sepolia using Chainlink's Cross-Chain Interoperability Protocol (CCIP) with proper balance tracking.

## Installation

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install
```

## Configuration

Copy the example environment file and add your private key:

```bash
cp .env.example .env
```

Edit `.env` and set your testnet private key:

```
PRIVATE_KEY=0x...
```

## Running Tests

The tests demonstrate proper balance tracking for CCIP transactions. Each test records the starting balance, executes the CCIP transaction, and verifies that the balance difference equals the fee paid.

### Sepolia → Hedera

```bash
# Native ETH payment with balance tracking
forge test --match-test test_SendMessageWithNativeETH -vvv

# LINK payment with balance tracking
forge test --match-test test_SendMessageWithLINK --match-contract SepoliaCCIPTest -vvv
```

### Hedera → Sepolia

```bash
# Native HBAR payment with balance tracking
forge test --match-test test_SendMessageWithNativeHBAR -vvv

# WHBAR payment with balance tracking
forge test --match-test test_SendMessageWithWHBAR -vvv

# LINK payment with balance tracking
forge test --match-test test_SendMessageWithLINK --match-contract HederaCCIPTest -vvv
```

### Build

```bash
forge build
```

## Network Details

### Hedera Testnet
- Chain ID: 296
- RPC: https://testnet.hashio.io/api
- CCIP Router: 0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4
- Chain Selector: 222782988166878823

### Ethereum Sepolia
- Chain ID: 11155111
- RPC: https://ethereum-sepolia-rpc.publicnode.com
- CCIP Router: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
- Chain Selector: 16015286601757825753

## Token Addresses

### Hedera Testnet
- LINK: 0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6
- WHBAR: 0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed

### Ethereum Sepolia
- LINK: 0x779877A7B0D9E8603169DdbD7836e478b4624789

## Getting Testnet Funds

- Hedera HBAR: https://portal.hedera.com/faucet
- Hedera LINK: https://faucets.chain.link/hedera-testnet
- Sepolia ETH: https://faucets.chain.link/sepolia

## License

MIT
