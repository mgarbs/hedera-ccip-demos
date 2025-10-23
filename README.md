# Hedera CCIP Cross-Chain Messaging

Send messages between Hedera and Sepolia using Chainlink CCIP.

## Quick Start

### 1. Install Dependencies
```bash
forge install
```

### 2. Setup Environment

Create a `.env` file in the project root:

```bash
# Hedera Configuration
HEDERA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
HEDERA_SENDER_ADDRESS=
HEDERA_RECEIVER_ADDRESS=

# Sepolia Configuration
SEPOLIA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY
SEPOLIA_SENDER_ADDRESS=
SEPOLIA_RECEIVER_ADDRESS=
```

**Getting Your Private Keys:**
- Export from MetaMask or your wallet (starts with `0x`)
- **Never commit your `.env` file!**

**Getting an RPC URL:**
- Sign up for free at [Alchemy](https://www.alchemy.com/) or [Infura](https://infura.io/)
- Create a Sepolia app and copy the HTTPS URL

**Getting Testnet Funds:**
- **Hedera HBAR**: [Hedera Faucet](https://portal.hedera.com/faucet) (~100 HBAR)
- **Sepolia ETH**: [Sepolia Faucet](https://sepoliafaucet.com/) (~0.5 ETH)
- **LINK tokens**: [Chainlink Faucet](https://faucets.chain.link/sepolia)

### 3. Deploy Contracts

```bash
./deploy.sh both
```

This will deploy to both chains and show output like:
```
CCIPSender deployed to: 0xABCD1234...
CCIPMessageReceiver deployed to: 0xEF567890...
```

**Copy these addresses** and update your `.env` file:
```bash
HEDERA_SENDER_ADDRESS=0xABCD1234...
HEDERA_RECEIVER_ADDRESS=0xEF567890...
SEPOLIA_SENDER_ADDRESS=0x12345678...
SEPOLIA_RECEIVER_ADDRESS=0x98765432...
```

### 4. Send Messages

**From Hedera to Sepolia:**
```bash
./send-hedera.sh hbar    # Pay with HBAR
./send-hedera.sh link    # Pay with LINK
```

**From Sepolia to Hedera:**
```bash
./send-sepolia.sh eth    # Pay with ETH
./send-sepolia.sh link   # Pay with LINK
```

Each script will show:
- Your current balances
- Transaction details
- Message ID for tracking
- Links to block explorers

### 5. Verify Messages

Wait 10-20 minutes, then check:
```bash
./check-messages.sh both
```

Or track in real-time on [CCIP Explorer](https://ccip.chain.link/)

## Testing

Run all tests:
```bash
forge test -vv
```

Test specific payment methods:
```bash
forge test --match-test test_SendMessageWithLINK -vvv
forge test --match-test test_SendMessageWithWHBAR -vvv
forge test --match-test test_SendMessageWithNativeHBAR -vvv
```

Run tests for a specific chain:
```bash
forge test --match-contract HederaCCIPTest -vv
forge test --match-contract SepoliaCCIPTest -vv
```

## What's Happening

The project demonstrates Chainlink CCIP cross-chain messaging:

1. **Deploy** contracts (`CCIPSender` and `CCIPMessageReceiver`) to both chains
2. **Send** a message from one chain using the sender contract
3. **CCIP** routes the message across chains (10-20 minutes)
4. **Receive** the message on the destination chain's receiver contract

You can pay CCIP fees with:
- **Native tokens**: HBAR or ETH (auto-wrapped to WHBAR on Hedera)
- **LINK tokens**: Available on both chains

Each transaction includes detailed logging with:
- Current balances before sending
- Transaction hash and block info
- Direct links to CCIP Explorer and block explorers
- Commands to verify receipt on destination

## Contract Addresses (2025)

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
│   ├── SendHederaToSepolia*.s.sol  # Send from Hedera
│   └── SendSepoliaToHedera*.s.sol  # Send from Sepolia
├── test/
│   ├── HederaCCIP.t.sol            # Hedera tests
│   ├── SepoliaCCIP.t.sol           # Sepolia tests
│   └── utils/CCIPTestBase.sol      # Test utilities
├── deploy.sh                        # Deploy helper
├── send-hedera.sh                   # Send from Hedera
├── send-sepolia.sh                  # Send from Sepolia
└── check-messages.sh                # Check received messages
```

## Resources

- [Chainlink CCIP Docs](https://docs.chain.link/ccip)
- [Hedera Docs](https://docs.hedera.com/)
- [CCIP Explorer](https://ccip.chain.link/)
