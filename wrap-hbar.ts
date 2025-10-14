/**
 * Wrap HBAR to WHBAR on Hedera Testnet
 *
 * This script wraps native HBAR into WHBAR (Wrapped HBAR)
 */

import "dotenv/config";
import { createPublicClient, createWalletClient, http, parseEther } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'

// Custom Hedera testnet chain configuration
const hederaTestnet = {
  id: 296,
  name: 'Hedera Testnet',
  network: 'hedera-testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'HBAR',
    symbol: 'HBAR',
  },
  rpcUrls: {
    default: {
      http: ['https://testnet.hashio.io/api'],
    },
    public: {
      http: ['https://testnet.hashio.io/api'],
    },
  },
  blockExplorers: {
    default: { name: 'HashScan', url: 'https://hashscan.io/testnet' },
  },
  testnet: true,
} as const

const WHBAR_ADDRESS = '0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed' as `0x${string}`

async function main() {
  // Check for private key
  let privateKey = process.env.PRIVATE_KEY
  if (!privateKey) {
    console.error('❌ Error: PRIVATE_KEY environment variable is required')
    console.log('\nSet it with: export PRIVATE_KEY=0x...')
    process.exit(1)
  }

  // Add 0x prefix if not present
  if (!privateKey.startsWith('0x')) {
    privateKey = '0x' + privateKey
  }

  console.log('🔄 Wrap HBAR to WHBAR on Hedera Testnet\n')

  // Create account from private key
  const account = privateKeyToAccount(privateKey as `0x${string}`)
  console.log(`📝 Using account: ${account.address}\n`)

  // Create Hedera clients
  const hederaPublicClient = createPublicClient({
    chain: hederaTestnet,
    transport: http(),
  })

  const hederaWalletClient = createWalletClient({
    account,
    chain: hederaTestnet,
    transport: http(),
  })

  // Check HBAR balance (native HBAR uses 18 decimals in EVM representation)
  const hbarBalance = await hederaPublicClient.getBalance({ address: account.address })
  console.log(`HBAR Balance: ${Number(hbarBalance) / 1e18} HBAR`)

  // Check WHBAR balance (WHBAR uses 8 decimals like native HBAR)
  const whbarBalance = await hederaPublicClient.readContract({
    address: WHBAR_ADDRESS,
    abi: [{
      name: 'balanceOf',
      type: 'function',
      stateMutability: 'view',
      inputs: [{ name: 'account', type: 'address' }],
      outputs: [{ name: 'balance', type: 'uint256' }],
    }],
    functionName: 'balanceOf',
    args: [account.address],
  })
  console.log(`WHBAR Balance: ${Number(whbarBalance) / 1e8} WHBAR\n`)

  // Amount to wrap - 50 HBAR should be plenty for fees
  // Note: We send with 18 decimals (EVM HBAR) but receive WHBAR with 8 decimals
  const wrapAmount = parseEther('50')
  console.log(`💰 Wrapping ${Number(wrapAmount) / 1e18} HBAR to WHBAR...\n`)

  if (hbarBalance < wrapAmount) {
    console.error('❌ Insufficient HBAR balance')
    process.exit(1)
  }

  // Call the deposit function on WHBAR contract (sends HBAR, receives WHBAR)
  const txHash = await hederaWalletClient.writeContract({
    address: WHBAR_ADDRESS,
    abi: [{
      name: 'deposit',
      type: 'function',
      stateMutability: 'payable',
      inputs: [],
      outputs: [],
    }],
    functionName: 'deposit',
    value: wrapAmount,
  })

  console.log(`⏳ Transaction submitted: ${txHash}`)
  console.log(`   https://hashscan.io/testnet/transaction/${txHash}\n`)

  // Wait for confirmation
  const receipt = await hederaPublicClient.waitForTransactionReceipt({
    hash: txHash,
    confirmations: 2,
  })

  if (receipt.status === 'success') {
    console.log('✅ HBAR wrapped successfully!\n')

    // Check new balances
    const newHbarBalance = await hederaPublicClient.getBalance({ address: account.address })
    const newWhbarBalance = await hederaPublicClient.readContract({
      address: WHBAR_ADDRESS,
      abi: [{
        name: 'balanceOf',
        type: 'function',
        stateMutability: 'view',
        inputs: [{ name: 'account', type: 'address' }],
        outputs: [{ name: 'balance', type: 'uint256' }],
      }],
      functionName: 'balanceOf',
      args: [account.address],
    })

    console.log('📊 New Balances:')
    console.log(`   HBAR: ${Number(newHbarBalance) / 1e18} HBAR`)
    console.log(`   WHBAR: ${Number(newWhbarBalance) / 1e8} WHBAR\n`)
    console.log('🎉 You can now use WHBAR for CCIP fees!')
  } else {
    console.error('❌ Transaction failed')
    process.exit(1)
  }
}

main().catch((error) => {
  console.error('❌ Error:', error)
  process.exit(1)
})
