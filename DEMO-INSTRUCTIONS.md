# CCIP JavaScript SDK Demo: Hedera to Sepolia

This demo shows how to use the CCIP JavaScript SDK to transfer tokens cross-chain from Hedera Testnet to Ethereum Sepolia.

## What This Demo Does

The demo script (`demo-hedera-sepolia.ts`) demonstrates a complete CCIP cross-chain token transfer workflow:

1. ✅ **Check Token Support** - Verify LINK token is supported on the Hedera→Sepolia lane
2. ✅ **Check & Approve** - Check allowance and approve the CCIP router to spend tokens
3. ✅ **Get Transfer Fee** - Calculate the fee required for the cross-chain transfer (in HBAR)
4. ✅ **Get Supported Fee Tokens** - List all tokens that can be used to pay fees
5. ✅ **Get Rate Limits** - Check the lane's rate limiting configuration
6. ✅ **Execute Transfer** - Send 0.01 LINK from Hedera to Sepolia
7. ✅ **Monitor Status** - Track the transfer status on the destination chain

## Prerequisites

Before running the demo, you'll need:

1. **Node.js and pnpm** (already installed if you followed setup)
2. **A funded wallet on Hedera Testnet** with:
   - Some HBAR (for gas fees) - Get from [Hedera Portal](https://portal.hedera.com/faucet)
   - Some LINK tokens - Get from [Chainlink Faucet](https://faucets.chain.link/hedera-testnet)
3. **Your wallet's private key**

## Setup Instructions

### 1. Install Dependencies (if not already done)

```bash
cd /Users/acehilm/ccip-javascript-sdk
pnpm install
pnpm build
```

### 2. Set Your Private Key

Export your private key as an environment variable:

```bash
export PRIVATE_KEY=0x0000000000000000000000000000000000000000000000000000000000000000
```

⚠️ **Security Warning**: Never commit your private key or share it. Use a testnet wallet only.

### 3. Fund Your Wallet

Get testnet tokens:

- **HBAR**: Visit [Hedera Portal Faucet](https://portal.hedera.com/faucet)
- **LINK**: Visit [Chainlink Faucet](https://faucets.chain.link/hedera-testnet)

You'll need:
- At least 0.1 HBAR for transaction fees
- At least 0.01 LINK to transfer

## Running the Demo

Execute the demo script:

```bash
npx tsx demo-hedera-sepolia.ts
```

### Expected Output

You should see output like this:

```
🚀 CCIP Demo: Hedera Testnet -> Ethereum Sepolia

📝 Using account: 0x1234...5678

═══════════════════════════════════════════════════════════
STEP 1: Check Token Support
═══════════════════════════════════════════════════════════

LINK Token supported on Sepolia lane: ✅

═══════════════════════════════════════════════════════════
STEP 2: Check Allowance & Approve Router
═══════════════════════════════════════════════════════════

Current allowance: 0 wei
Transfer amount: 10000000000000000 wei (0.01 LINK)

⏳ Approving router to spend tokens...
✅ Approval transaction: 0xabc...def

═══════════════════════════════════════════════════════════
STEP 3: Get Transfer Fee
═══════════════════════════════════════════════════════════

Transfer fee (in HBAR): 50000000000000000 wei
Transfer fee (human): 0.05 HBAR

═══════════════════════════════════════════════════════════
STEP 4: Get Supported Fee Tokens
═══════════════════════════════════════════════════════════

Supported fee tokens:
  1. 0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6
  2. 0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed

═══════════════════════════════════════════════════════════
STEP 5: Get Rate Limits
═══════════════════════════════════════════════════════════

Lane rate limits:
  Enabled: true
  Capacity: 1000000000000000000000
  Tokens: 950000000000000000000
  Rate: 100000000000000000/sec

═══════════════════════════════════════════════════════════
STEP 6: Execute Cross-Chain Transfer
═══════════════════════════════════════════════════════════

⏳ Initiating cross-chain transfer...
   From: Hedera Testnet
   To: Ethereum Sepolia
   Amount: 0.01 LINK
   Destination: 0x1234...5678

✅ Transfer initiated!
   Transaction hash: 0xabc...123
   Message ID: 0xdef...456
   Block number: 12345678

═══════════════════════════════════════════════════════════
STEP 7: Monitor Transfer Status
═══════════════════════════════════════════════════════════

⏳ Checking transfer status on Sepolia...
   (This may take several minutes for cross-chain finality)

   Attempt 1/20: Status not available yet...
   Attempt 2/20: Status not available yet...
📊 Transfer Status: Success

✅ Transfer completed successfully!

═══════════════════════════════════════════════════════════
Monitoring Links
═══════════════════════════════════════════════════════════

🔍 Hedera Transaction:
   https://hashscan.io/testnet/transaction/0xabc...123

🔍 CCIP Explorer:
   https://ccip.chain.link/msg/0xdef...456

═══════════════════════════════════════════════════════════

✅ Demo completed!
```

## Understanding the Demo

### Network Configuration

**Hedera Testnet:**
- Chain ID: 296
- RPC: https://testnet.hashio.io/api
- CCIP Router: `0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4`
- Chain Selector: `222782988166878823`
- LINK Token: `0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6`

**Ethereum Sepolia:**
- Chain ID: 11155111
- CCIP Router: `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
- Chain Selector: `16015286601757825753`
- LINK Token: `0x779877A7B0D9E8603169DdbD7836e478b4624789`

### Key Concepts

1. **Chain Selectors**: Unique identifiers for each blockchain in CCIP
2. **Router Address**: The CCIP router contract that handles cross-chain messages
3. **OnRamp/OffRamp**: Entry and exit points for cross-chain transfers
4. **Fee Tokens**: Tokens that can be used to pay for CCIP transfers (LINK, native tokens)
5. **Rate Limits**: Throttling mechanisms to control cross-chain transfer volume

### Transfer Flow

1. User approves CCIP router to spend tokens
2. User calls `transferTokens()` which:
   - Locks tokens on source chain (Hedera)
   - Sends message via CCIP
   - Pays fee in HBAR (native token)
3. CCIP processes the message
4. Tokens are minted/unlocked on destination chain (Sepolia)

### Monitoring

- **Source Transaction**: View on [HashScan](https://hashscan.io/testnet)
- **CCIP Message**: Track on [CCIP Explorer](https://ccip.chain.link)
- **Destination Transaction**: View on [Sepolia Etherscan](https://sepolia.etherscan.io)

## Customizing the Demo

### Change Transfer Amount

Edit line 113 in `demo-hedera-sepolia.ts`:

```typescript
const transferAmount = parseEther('0.01') // Change to your desired amount
```

### Use Different Fee Token

To pay fees in LINK instead of HBAR, add `feeTokenAddress` parameter:

```typescript
const { txHash, messageId } = await ccipClient.transferTokens({
  // ... other params ...
  feeTokenAddress: HEDERA_CONFIG.linkToken, // Pay fee in LINK
})
```

### Transfer to Different Address

Change the destination address on line 114:

```typescript
const destinationAddress = '0x...' // Replace with destination address
```

### Add Custom Message

You can send arbitrary data along with the token transfer:

```typescript
const { txHash, messageId } = await ccipClient.transferTokens({
  // ... other params ...
  message: 'Hello from Hedera!', // Custom message data
})
```

## Troubleshooting

### Error: Insufficient Balance

Make sure you have enough:
- LINK tokens to transfer (at least 0.01)
- HBAR for gas fees (at least 0.1)

### Error: Token Not Supported

Verify you're using a supported token for the lane. Check [CCIP Directory](https://docs.chain.link/ccip/directory/testnet) for supported tokens.

### Transfer Status Stuck

Cross-chain transfers can take 5-20 minutes depending on:
- Network congestion
- Finality requirements
- CCIP confirmation thresholds

Be patient and check the CCIP Explorer link.

### RPC Connection Issues

If you get RPC errors, try:
- Using a different RPC endpoint
- Adding retry logic
- Checking network status

## Additional Resources

- [CCIP Documentation](https://docs.chain.link/ccip)
- [CCIP JavaScript SDK Docs](https://docs.chain.link/ccip/ccip-javascript-sdk)
- [CCIP Directory](https://docs.chain.link/ccip/directory)
- [Hedera Documentation](https://docs.hedera.com)
- [Viem Documentation](https://viem.sh)

## Next Steps

After running this demo, you can:

1. **Try the NextJS UI Example**: Run `pnpm dev-example` to see the full UI
2. **Explore Other Lanes**: Transfer between different chain pairs
3. **Build Your Own App**: Use the SDK in your own project
4. **Test Message Sending**: Try `sendCCIPMessage()` to send arbitrary data

## Support

- **CCIP Issues**: [Chainlink GitHub](https://github.com/smartcontractkit/ccip)
- **SDK Issues**: [CCIP JS SDK GitHub](https://github.com/smartcontractkit/ccip-javascript-sdk/issues)
- **Hedera Support**: [Hedera Discord](https://hedera.com/discord)
