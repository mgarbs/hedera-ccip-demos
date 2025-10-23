# Hedera CCIP Cross-Chain Messaging

Send messages between Hedera and Sepolia using Chainlink CCIP.

## Quick Start

### 1. Install
```bash
forge install
```

### 2. Setup `.env`
```bash
HEDERA_PRIVATE_KEY=0x...
SEPOLIA_PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
```

Get testnet funds:
- [Hedera Faucet](https://portal.hedera.com/faucet)
- [Sepolia Faucet](https://sepoliafaucet.com/)

### 3. Deploy
```bash
./deploy.sh both
```

Update `.env` with deployed contract addresses.

### 4. Send Messages

**Hedera → Sepolia:**
```bash
./send-hedera.sh hbar    # Pay with HBAR
./send-hedera.sh link    # Pay with LINK
```

**Sepolia → Hedera:**
```bash
./send-sepolia.sh eth    # Pay with ETH
./send-sepolia.sh link   # Pay with LINK
```

### 5. Check Messages
```bash
./check-messages.sh both
```

## Testing

```bash
forge test -vv
```

Test specific payment methods:
```bash
forge test --match-test test_SendMessageWithLINK -vvv
forge test --match-test test_SendMessageWithWHBAR -vvv
```

## What's Happening

- Contracts send cross-chain messages using Chainlink CCIP
- Messages take 10-20 minutes to arrive
- You can pay fees with native tokens (HBAR/ETH) or LINK
- Track messages on [CCIP Explorer](https://ccip.chain.link/)

## Addresses (2025)

**Hedera Testnet:**
- Router: `0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4`
- LINK: `0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6`

**Sepolia:**
- Router: `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
- LINK: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
