#!/bin/bash

# Sepolia to Hedera Cross-Chain Message Sender
# Usage: ./send-sepolia.sh [eth|link]

set -e

# Load environment variables
source .env

# Default to ETH if no argument provided
PAYMENT_METHOD=${1:-eth}

case $PAYMENT_METHOD in
  eth)
    echo ""
    echo "🚀 Sending message from Sepolia to Hedera (paying with ETH)"
    echo ""
    forge script script/SendSepoliaToHederaWithETH.s.sol \
      --rpc-url sepolia \
      --broadcast \
      -vvv
    ;;
  link)
    echo ""
    echo "🚀 Sending message from Sepolia to Hedera (paying with LINK)"
    echo ""
    forge script script/SendSepoliaToHederaWithLINK.s.sol \
      --rpc-url sepolia \
      --broadcast \
      -vvv
    ;;
  *)
    echo "Usage: $0 [eth|link]"
    echo ""
    echo "Payment options:"
    echo "  eth  - Pay with native ETH (default)"
    echo "  link - Pay with LINK tokens"
    exit 1
    ;;
esac
