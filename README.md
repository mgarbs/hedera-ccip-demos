# Hedera CCIP Cross-Chain Messaging Demo

Send cross-chain messages between Hedera Testnet and Sepolia using Chainlink CCIP with live transaction monitoring.

## Features

✅ **Hedera → Sepolia** messages with payment options: HBAR, WHBAR, or LINK
✅ **Sepolia → Hedera** messages with payment options: ETH or LINK
✅ **Live transaction monitoring** with block explorer links and CCIP tracking
✅ **Easy-to-use helper scripts** for deployment and sending
✅ **Comprehensive tests** demonstrating all payment methods

## Quick Start

### 1. Install Dependencies

```bash
forge install
```

### 2. Setup Environment

Create a `.env` file:

```bash
# Hedera Configuration
HEDERA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
HEDERA_SENDER_ADDRESS=
HEDERA_RECEIVER_ADDRESS=

# Sepolia Configuration
SEPOLIA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
SEPOLIA_SENDER_ADDRESS=
SEPOLIA_RECEIVER_ADDRESS=
```

Get testnet funds:
- **Hedera HBAR**: [Hedera Faucet](https://portal.hedera.com/faucet)
- **Sepolia ETH**: [Sepolia Faucet](https://sepoliafaucet.com/)
- **LINK tokens**: [Chainlink Faucet](https://faucets.chain.link/sepolia)

### 3. Deploy Contracts

```bash
./deploy.sh both
```

Update your `.env` with the deployed contract addresses shown in the output.

### 4. Send Messages

**From Hedera to Sepolia:**
```bash
./send-hedera.sh hbar    # Pay with HBAR (auto-wraps to WHBAR)
./send-hedera.sh whbar   # Pay with Wrapped HBAR
./send-hedera.sh link    # Pay with LINK
```

**From Sepolia to Hedera:**
```bash
./send-sepolia.sh eth    # Pay with ETH
./send-sepolia.sh link   # Pay with LINK
```

### 5. Check Messages (after 10-20 min)

```bash
./check-messages.sh both
```

## Testing

Run the test suite to verify all payment methods:

```bash
# Run all tests
forge test -vv

# Test specific payment methods
forge test --match-test test_SendMessageWithLINK -vvv
forge test --match-test test_SendMessageWithWHBAR -vvv
forge test --match-test test_SendMessageWithNativeHBAR -vvv

# Test specific chains
forge test --match-contract HederaCCIPTest -vv
forge test --match-contract SepoliaCCIPTest -vv
```

**Test Coverage:**
- ✅ Deployment verification
- ✅ HBAR payment (auto-wrapped to WHBAR)
- ✅ WHBAR payment
- ✅ LINK payment on both chains
- ✅ Fee token enumeration

## Live Transaction Output

When you send a message, you'll see detailed tracking information:

```
========================================
  HEDERA -> SEPOLIA (Pay with HBAR)
========================================

Source: Hedera Testnet
Destination: Sepolia Testnet
Sender Contract: 0x...
Receiver Contract: 0x...
Your Address: 0x...

Current Balance: 906 HBAR

Sending message: Hello from Hedera! Paid with native HBAR at block 26592141
Sending 5 HBAR (excess will remain in sender contract)...

========================================
  TRANSACTION SUCCESSFUL!
========================================

Message ID: 0xabcd1234...

Block Number: 26592141
Timestamp: 1234567890

----------------------------------------
  Track Your Transaction
----------------------------------------

CCIP Explorer:
https://ccip.chain.link/msg/0xabcd1234...

Hedera HashScan:
https://hashscan.io/testnet/transaction/[YOUR_TX_HASH]

----------------------------------------
  Verify on Destination
----------------------------------------

Wait 10-20 minutes, then run:

cast call 0x... "getMessageCount()" --rpc-url sepolia
cast call 0x... "getLastMessage()" --rpc-url sepolia

========================================
```

## Contract Addresses (2025 Updated)

### Hedera Testnet
- **CCIP Router**: `0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4`
- **LINK Token**: `0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6`
- **Wrapped HBAR**: `0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed`
- **Chain Selector**: `222782988166878823`

### Sepolia Testnet
- **CCIP Router**: `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
- **LINK Token**: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
- **Chain Selector**: `16015286601757825753`

## Project Structure

```
├── src/
│   ├── CCIPSender.sol              # Send CCIP messages
│   └── CCIPReceiver.sol            # Receive CCIP messages
├── script/
│   ├── DeployHedera.s.sol          # Deploy to Hedera
│   ├── DeploySepolia.s.sol         # Deploy to Sepolia
│   ├── SendHederaToSepoliaWith*.s.sol   # Hedera → Sepolia (HBAR/WHBAR/LINK)
│   └── SendSepoliaToHederaWith*.s.sol   # Sepolia → Hedera (ETH/LINK)
├── test/
│   ├── HederaCCIP.t.sol            # Hedera tests (5 tests)
│   ├── SepoliaCCIP.t.sol           # Sepolia tests (3 tests)
│   └── utils/CCIPTestBase.sol      # Shared test utilities
├── deploy.sh                        # Deploy helper
├── send-hedera.sh                   # Send from Hedera helper
├── send-sepolia.sh                  # Send from Sepolia helper
└── check-messages.sh                # Check received messages
```

## Important Notes

**HBAR Auto-Wrapping:**
When you pay with native HBAR on Hedera, the CCIP Router automatically wraps it to WHBAR internally. This is why CCIP Explorer shows WHBAR even when you pay with HBAR - both payment methods work the same way!

**Message Timing:**
Cross-chain messages take **10-20 minutes** to arrive. Use the CCIP Explorer link to track progress.

**Gas Limits:**
The contracts use a fixed 200,000 gas limit for destination execution. Adjust in `CCIPSender.sol` if needed.

## Troubleshooting

**"Insufficient balance" error:**
- Get more testnet funds from the faucets above
- For HBAR: Need ~10 HBAR for gas + fees
- For ETH: Need ~0.2 ETH for gas + fees

**Message not arriving:**
- Wait the full 20 minutes
- Check CCIP Explorer for status
- Verify receiver address in `.env` is correct

**"Router not available" error:**
- Check your RPC endpoints are working
- Verify CCIP is operational: [CCIP Status](https://docs.chain.link/ccip/supported-networks)

## Resources

- [Chainlink CCIP Docs](https://docs.chain.link/ccip)
- [Hedera Docs](https://docs.hedera.com/)
- [CCIP Explorer](https://ccip.chain.link/)
- [Foundry Book](https://book.getfoundry.sh/)

## License

MIT
