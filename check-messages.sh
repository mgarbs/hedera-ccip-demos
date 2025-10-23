#!/bin/bash

# Check received messages on both chains
# Usage: ./check-messages.sh [hedera|sepolia|both]

set -e

# Load environment variables
source .env

NETWORK=${1:-both}

check_hedera() {
    echo ""
    echo "========================================"
    echo "  HEDERA TESTNET - Received Messages"
    echo "========================================"
    echo ""
    echo "Receiver Contract: $HEDERA_RECEIVER_ADDRESS"
    echo ""

    MESSAGE_COUNT=$(cast call $HEDERA_RECEIVER_ADDRESS "getMessageCount()" --rpc-url hedera_testnet)
    echo "Total Messages Received: $MESSAGE_COUNT"

    if [ "$MESSAGE_COUNT" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        echo ""
        echo "Last Message:"
        cast call $HEDERA_RECEIVER_ADDRESS "getLastMessage()" --rpc-url hedera_testnet
    else
        echo ""
        echo "No messages received yet."
    fi
    echo ""
}

check_sepolia() {
    echo ""
    echo "========================================"
    echo "  SEPOLIA TESTNET - Received Messages"
    echo "========================================"
    echo ""
    echo "Receiver Contract: $SEPOLIA_RECEIVER_ADDRESS"
    echo ""

    MESSAGE_COUNT=$(cast call $SEPOLIA_RECEIVER_ADDRESS "getMessageCount()" --rpc-url sepolia)
    echo "Total Messages Received: $MESSAGE_COUNT"

    if [ "$MESSAGE_COUNT" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        echo ""
        echo "Last Message:"
        cast call $SEPOLIA_RECEIVER_ADDRESS "getLastMessage()" --rpc-url sepolia
    else
        echo ""
        echo "No messages received yet."
    fi
    echo ""
}

case $NETWORK in
  hedera)
    check_hedera
    ;;
  sepolia)
    check_sepolia
    ;;
  both)
    check_hedera
    check_sepolia
    ;;
  *)
    echo "Usage: $0 [hedera|sepolia|both]"
    echo ""
    echo "Options:"
    echo "  hedera  - Check messages on Hedera only"
    echo "  sepolia - Check messages on Sepolia only"
    echo "  both    - Check messages on both chains (default)"
    exit 1
    ;;
esac

echo "========================================"
echo ""
