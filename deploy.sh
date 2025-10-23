#!/bin/bash

# Deploy CCIP contracts to testnets
# Usage: ./deploy.sh [hedera|sepolia|both]

set -e

# Load environment variables
source .env

NETWORK=${1:-both}

deploy_hedera() {
    echo ""
    echo "🚀 Deploying to Hedera Testnet"
    echo ""
    forge script script/DeployHedera.s.sol \
      --rpc-url hedera_testnet \
      --broadcast \
      -vvv
}

deploy_sepolia() {
    echo ""
    echo "🚀 Deploying to Sepolia Testnet"
    echo ""
    forge script script/DeploySepolia.s.sol \
      --rpc-url sepolia \
      --broadcast \
      -vvv
}

case $NETWORK in
  hedera)
    deploy_hedera
    ;;
  sepolia)
    deploy_sepolia
    ;;
  both)
    deploy_hedera
    echo ""
    echo "========================================"
    echo ""
    deploy_sepolia
    ;;
  *)
    echo "Usage: $0 [hedera|sepolia|both]"
    echo ""
    echo "Options:"
    echo "  hedera  - Deploy only to Hedera Testnet"
    echo "  sepolia - Deploy only to Sepolia Testnet"
    echo "  both    - Deploy to both networks (default)"
    exit 1
    ;;
esac

echo ""
echo "========================================"
echo "  DEPLOYMENT COMPLETE"
echo "========================================"
echo ""
echo "Don't forget to update your .env file with the deployed addresses!"
echo ""
