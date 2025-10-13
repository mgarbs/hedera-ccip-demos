# CCIP JavaScript SDK - Hedera Demo

Private repository demonstrating the [CCIP JavaScript SDK](https://github.com/smartcontractkit/ccip-javascript-sdk) with Hedera Testnet integration.

## 🎯 What's Included

This repo demonstrates **bi-directional cross-chain messaging** between Hedera Testnet and Ethereum Sepolia using Chainlink's CCIP.

### Working Demos

✅ **Hedera → Sepolia** - Send messages from Hedera to Sepolia (pay fee in LINK or HBAR)
✅ **Sepolia → Hedera** - Send messages from Sepolia to Hedera (pay fee in ETH or LINK)
✅ **Read-Only Queries** - Query CCIP configuration without transactions

## 🚀 Quick Start

```bash
# Install dependencies
pnpm install && pnpm build

# Run read-only demo (no wallet needed)
npx tsx demo-hedera-readonly.ts

# Run Hedera → Sepolia demo (pay with LINK)
export PRIVATE_KEY=0x...
npx tsx demo-hedera-message.ts

# Run Hedera → Sepolia demo (pay with HBAR)
export PRIVATE_KEY=0x...
npx tsx demo-hedera-message-hbar.ts

# Run Sepolia → Hedera demo (needs ETH)
export PRIVATE_KEY=0x...
npx tsx demo-sepolia-hedera.ts
```

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 3 steps
- **[DEMO-INSTRUCTIONS.md](DEMO-INSTRUCTIONS.md)** - Complete setup guide
- **[DEMO-SUMMARY.md](DEMO-SUMMARY.md)** - Technical deep dive

## 🔑 Prerequisites

1. **Node.js & pnpm** installed
2. **Testnet funds:**
   - HBAR: https://portal.hedera.com/faucet
   - LINK (Hedera): https://faucets.chain.link/hedera-testnet
   - Sepolia ETH: https://faucets.chain.link/sepolia
3. **Private key** from a testnet wallet

## 📁 Demo Files

| File | Description | Requires Funds |
|------|-------------|----------------|
| `demo-hedera-readonly.ts` | Query CCIP config | ❌ No |
| `demo-hedera-message.ts` | Hedera → Sepolia message | ✅ LINK |
| `demo-hedera-message-hbar.ts` | Hedera → Sepolia message | ✅ HBAR |
| `demo-sepolia-hedera.ts` | Sepolia → Hedera message | ✅ ETH |
| `demo-hedera-sepolia.ts` | Original token transfer demo | ⚠️ Pools not ready |

## ✨ Features Demonstrated

- ✅ Cross-chain messaging (Hedera ↔ Sepolia)
- ✅ Multiple fee payment options (HBAR, LINK, ETH)
- ✅ Token approval and allowance checking
- ✅ Fee calculation and estimation
- ✅ Transfer status monitoring
- ✅ Type-safe API with TypeScript/Viem
- ✅ Configuration queries (supported tokens, rate limits, etc.)

## 🔗 Network Details

### Hedera Testnet
- **Chain ID:** 296
- **RPC:** https://testnet.hashio.io/api
- **CCIP Router:** `0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4`
- **Chain Selector:** `222782988166878823`

### Ethereum Sepolia
- **Chain ID:** 11155111
- **CCIP Router:** `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
- **Chain Selector:** `16015286601757825753`

## 🛠️ SDK Methods Used

| Method | Purpose |
|--------|---------|
| `createClient()` | Initialize CCIP client |
| `isTokenSupported()` | Check if token works on lane |
| `getSupportedFeeTokens()` | List fee payment options |
| `getFee()` | Calculate transfer cost |
| `approveRouter()` | Approve token spending |
| `getAllowance()` | Check current allowance |
| `sendCCIPMessage()` | Send cross-chain message |
| `transferTokens()` | Transfer tokens (when pools ready) |
| `getTransferStatus()` | Monitor transfer progress |

## 📊 Example Output

```
🚀 CCIP Demo: Send Message from Hedera -> Sepolia

📝 Using account: 0xdfC61db3604E254611827Ecf0D42E6F4b2E256Ac

LINK Balance: 10.5 LINK
✅ LINK already approved

Message: "Hello from Hedera via CCIP! 🚀"
Message fee: 0.019 LINK

✅ Message sent!
   Transaction hash: 0xabc...123
   Message ID: 0xdef...456

📊 Transfer Status: Success
✅ Message delivered successfully!

🔍 CCIP Explorer: https://ccip.chain.link/msg/0xdef...456
```

## ⚠️ Known Limitations

- **Token Transfers:** LINK token pools not fully configured on Hedera testnet yet
- **Message-Only:** Currently limited to message passing (no token transfers)

## 🔄 Upstream Repository

This is a fork of the official CCIP JavaScript SDK with Hedera-specific demos added.

- **Upstream:** https://github.com/smartcontractkit/ccip-javascript-sdk
- **Original Docs:** https://docs.chain.link/ccip/ccip-javascript-sdk

## 📝 License

MIT License (matches upstream repository)

## 🤝 Contributing

This is a private demo repository. For issues with the CCIP SDK itself, please report to the [upstream repository](https://github.com/smartcontractkit/ccip-javascript-sdk/issues).

---

**Built with:**
- [CCIP JavaScript SDK](https://github.com/smartcontractkit/ccip-javascript-sdk)
- [Viem](https://viem.sh)
- [Hedera](https://hedera.com)
- [Chainlink CCIP](https://chain.link/ccip)
