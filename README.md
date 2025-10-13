# Hedera CCIP Demos

Demonstration of bi-directional cross-chain messaging between Hedera Testnet and Ethereum Sepolia using Chainlink's Cross-Chain Interoperability Protocol (CCIP).

## Installation

```bash
pnpm install
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

## Available Demos

### Read-Only Configuration Query

Query CCIP configuration without executing transactions:

```bash
pnpm run demo:readonly
```

### Hedera to Sepolia (LINK Payment)

> ℹ️ **Requires LINK tokens** — Get them from the [Hedera LINK faucet](https://faucets.chain.link/hedera-testnet)

Send a message from Hedera to Sepolia, paying fees in LINK:

```bash
pnpm run demo:hedera-sepolia-link
```

### Hedera to Sepolia (WHBAR Payment)

> ℹ️ **Requires WHBAR tokens** — If needed, wrap HBAR first: `pnpm run wrap-hbar`

Send a message from Hedera to Sepolia, paying fees in Wrapped HBAR:

```bash
pnpm run demo:hedera-sepolia-whbar
```

### Sepolia to Hedera (ETH Payment)

> ℹ️ **Requires Sepolia ETH** — Get it from the [Sepolia faucet](https://faucets.chain.link/sepolia)

Send a message from Sepolia to Hedera, paying fees in native ETH:

```bash
pnpm run demo:sepolia-hedera
```

## Network Details

### Hedera Testnet
- Chain ID: 296
- RPC: https://testnet.hashio.io/api
- CCIP Router: 0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4
- Chain Selector: 222782988166878823

### Ethereum Sepolia
- Chain ID: 11155111
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

## Notes

- All demos use testnet networks only
- Message delivery typically takes several minutes
- Token transfers are not yet supported due to incomplete token pool configuration on Hedera testnet
- WHBAR uses 8 decimals while most EVM tokens use 18 decimals

## License

MIT
