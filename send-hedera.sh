#!/bin/bash

# Hedera to Sepolia Cross-Chain Message Sender
# Usage: ./send-hedera.sh [hbar|whbar|link]

set -e

# Load environment variables
source .env

# Default to HBAR if no argument provided
PAYMENT_METHOD=${1:-hbar}

case $PAYMENT_METHOD in
  hbar)
    echo ""
    echo "🚀 Sending message from Hedera to Sepolia (paying with HBAR)"
    echo ""
    forge script script/SendHederaToSepoliaWithHBAR.s.sol \
      --rpc-url hedera_testnet \
      --broadcast \
      -vvv
    ;;
  whbar)
    echo ""
    echo "🚀 Sending message from Hedera to Sepolia (paying with WHBAR)"
    echo ""
    forge script script/SendHederaToSepoliaWithWHBAR.s.sol \
      --rpc-url hedera_testnet \
      --broadcast \
      -vvv
    ;;
  link)
    echo ""
    echo "🚀 Sending message from Hedera to Sepolia (paying with LINK)"
    echo ""
    forge script script/SendHederaToSepoliaWithLINK.s.sol \
      --rpc-url hedera_testnet \
      --broadcast \
      -vvv
    ;;
  *)
    echo "Usage: $0 [hbar|whbar|link]"
    echo ""
    echo "Payment options:"
    echo "  hbar  - Pay with native HBAR (default)"
    echo "  whbar - Pay with Wrapped HBAR"
    echo "  link  - Pay with LINK tokens"
    exit 1
    ;;
esac
