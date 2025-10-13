# CCIP JavaScript SDK - Quick Start Guide

## TL;DR - Run the Demo in 3 Steps

```bash
# 1. Navigate to the SDK directory
cd /Users/acehilm/ccip-javascript-sdk

# 2. Run the read-only demo (no wallet needed)
npx tsx demo-hedera-readonly.ts

# 3. (Optional) Run full demo with your wallet
export PRIVATE_KEY=0xyour_private_key_here
npx tsx demo-hedera-sepolia.ts
```

## What You'll See

### Read-Only Demo Output
```
🔍 CCIP Read-Only Demo: Hedera Testnet Configuration

Network Information
  Chain: Hedera Testnet
  CCIP Router: 0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4

Token Support Check
  LINK Token supported: ⚠️  (Pool being configured)

Supported Fee Tokens
  1. LINK - 0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6
  2. WHBAR - 0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed

OnRamp Address
  0xaE1CDf57B50e28D12D52916a550308F2682504bF
```

## Files Available

1. **`demo-hedera-readonly.ts`** - Query CCIP config (no wallet)
2. **`demo-hedera-sepolia.ts`** - Full cross-chain transfer
3. **`DEMO-INSTRUCTIONS.md`** - Detailed setup guide
4. **`DEMO-SUMMARY.md`** - Technical overview

## SDK Usage Example

```typescript
import * as CCIP from '@chainlink/ccip-js'
import { createPublicClient, http } from 'viem'

// Create CCIP client
const ccipClient = CCIP.createClient()

// Create public client
const publicClient = createPublicClient({
  chain: hederaTestnet,
  transport: http(),
})

// Check if token is supported
const isSupported = await ccipClient.isTokenSupported({
  client: publicClient,
  routerAddress: '0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4',
  destinationChainSelector: '16015286601757825753', // Sepolia
  tokenAddress: '0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6', // LINK
})
```

## Get Testnet Tokens

- **HBAR**: https://portal.hedera.com/faucet
- **LINK**: https://faucets.chain.link/hedera-testnet

## Key CCIP Methods

| Method | Use Case |
|--------|----------|
| `isTokenSupported()` | Check if token works on a lane |
| `getSupportedFeeTokens()` | Get fee payment options |
| `getFee()` | Calculate transfer cost |
| `approveRouter()` | Approve token spending |
| `transferTokens()` | Send cross-chain transfer |
| `getTransferStatus()` | Monitor transfer progress |

## Network Details

**Hedera → Sepolia Lane**
- Source Router: `0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4`
- Destination Router: `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
- Fee Options: HBAR, LINK, or WHBAR

## Learn More

- Full instructions: `DEMO-INSTRUCTIONS.md`
- Technical details: `DEMO-SUMMARY.md`
- CCIP Docs: https://docs.chain.link/ccip
- SDK Docs: https://docs.chain.link/ccip/ccip-javascript-sdk

---

**Ready to build?** Check out the demo scripts to see real examples!
