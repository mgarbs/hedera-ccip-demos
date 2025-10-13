/**
 * CCIP Demo: Send Message/Tokens from Ethereum Sepolia -> Hedera Testnet
 *
 * This demo sends a cross-chain message from Sepolia to Hedera, paying fee in ETH
 */

import * as CCIP from '@chainlink/ccip-js'
import { createPublicClient, createWalletClient, http } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { sepolia } from 'viem/chains'

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

// CCIP Configuration
const SEPOLIA_CONFIG = {
  routerAddress: '0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59' as `0x${string}`,
  chainSelector: '16015286601757825753',
  linkToken: '0x779877A7B0D9E8603169DdbD7836e478b4624789' as `0x${string}`,
}

const HEDERA_CONFIG = {
  routerAddress: '0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4' as `0x${string}`,
  chainSelector: '222782988166878823',
}

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

  console.log('🚀 CCIP Demo: Send Message from Sepolia -> Hedera\n')

  // Create account from private key
  const account = privateKeyToAccount(privateKey as `0x${string}`)
  console.log(`📝 Using account: ${account.address}\n`)

  // Initialize CCIP client
  const ccipClient = CCIP.createClient()

  // Create Sepolia clients with a more reliable RPC
  const sepoliaRpc = 'https://ethereum-sepolia-rpc.publicnode.com'

  const sepoliaPublicClient = createPublicClient({
    chain: sepolia,
    transport: http(sepoliaRpc),
  })

  const sepoliaWalletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(sepoliaRpc),
  })

  // Create Hedera client for monitoring
  const hederaPublicClient = createPublicClient({
    chain: hederaTestnet,
    transport: http(),
  })

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 1: Check Balance')
  console.log('═══════════════════════════════════════════════════════════\n')

  const balance = await sepoliaPublicClient.getBalance({ address: account.address })
  console.log(`ETH Balance: ${Number(balance) / 1e18} ETH\n`)

  if (balance < BigInt(5e16)) { // 0.05 ETH
    console.log('⚠️  Low balance! You may need more ETH.')
    console.log('   Get Sepolia ETH from: https://faucets.chain.link/sepolia\n')
  }

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 2: Check Supported Fee Tokens')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Fetching supported fee tokens...')
  const supportedFeeTokens = await ccipClient.getSupportedFeeTokens({
    client: sepoliaPublicClient,
    routerAddress: SEPOLIA_CONFIG.routerAddress,
    destinationChainSelector: HEDERA_CONFIG.chainSelector,
  })

  console.log(`\nYou can pay fees with any of these ${supportedFeeTokens.length} tokens:\n`)
  supportedFeeTokens.forEach((token, i) => {
    console.log(`  ${i + 1}. ${token}`)
  })
  console.log(`\nOr use native ETH to pay fees.\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 3: Get Message Fee (ETH vs LINK)')
  console.log('═══════════════════════════════════════════════════════════\n')

  const message = 'Hello from Sepolia to Hedera via CCIP! 🌉'
  console.log(`Message: "${message}"\n`)

  console.log('⏳ Calculating fees with different payment options...\n')

  // Option 1: Pay in native ETH
  const feeInEth = await ccipClient.getFee({
    client: sepoliaPublicClient,
    routerAddress: SEPOLIA_CONFIG.routerAddress,
    destinationAccount: account.address,
    destinationChainSelector: HEDERA_CONFIG.chainSelector,
    amount: 0n,
    tokenAddress: SEPOLIA_CONFIG.linkToken,
    message,
    // Not specifying feeTokenAddress = pay in native ETH
  })

  // Option 2: Pay in LINK
  const feeInLink = await ccipClient.getFee({
    client: sepoliaPublicClient,
    routerAddress: SEPOLIA_CONFIG.routerAddress,
    destinationAccount: account.address,
    destinationChainSelector: HEDERA_CONFIG.chainSelector,
    amount: 0n,
    tokenAddress: SEPOLIA_CONFIG.linkToken,
    message,
    feeTokenAddress: SEPOLIA_CONFIG.linkToken, // Pay in LINK
  })

  console.log(`Fee options:`)
  console.log(`  • Pay in ETH: ${Number(feeInEth) / 1e18} ETH`)
  console.log(`  • Pay in LINK: ${Number(feeInLink) / 1e18} LINK\n`)

  // Let's use ETH for this demo
  const fee = feeInEth
  const feeToken = 'ETH'

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 4: Send Cross-Chain Message')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Sending message via CCIP...')
  console.log(`   From: Ethereum Sepolia`)
  console.log(`   To: Hedera Testnet`)
  console.log(`   Destination: ${account.address}`)
  console.log(`   Message: "${message}"`)
  console.log(`   Fee payment: ${Number(fee) / 1e18} ${feeToken}\n`)

  const { txHash, messageId, txReceipt } = await ccipClient.sendCCIPMessage({
    client: sepoliaWalletClient,
    routerAddress: SEPOLIA_CONFIG.routerAddress,
    destinationChainSelector: HEDERA_CONFIG.chainSelector,
    destinationAccount: account.address,
    message,
    // Paying fee in native ETH (not specifying feeTokenAddress)
    writeContractParameters: {
      value: fee, // Include the fee as transaction value
    },
  })

  console.log(`✅ Message sent!`)
  console.log(`   Transaction hash: ${txHash}`)
  console.log(`   Message ID: ${messageId}`)
  console.log(`   Block number: ${txReceipt.blockNumber}\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 5: Monitor Message Status')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Checking message status on Hedera...')
  console.log('   (This may take several minutes for cross-chain finality)\n')

  // Poll for status
  let attempts = 0
  const maxAttempts = 20
  const pollInterval = 15000 // 15 seconds

  while (attempts < maxAttempts) {
    try {
      const status = await ccipClient.getTransferStatus({
        client: hederaPublicClient,
        destinationRouterAddress: HEDERA_CONFIG.routerAddress,
        sourceChainSelector: SEPOLIA_CONFIG.chainSelector,
        messageId,
      })

      if (status !== null) {
        const statusText = ['Untouched', 'InProgress', 'Success', 'Failure'][status]
        console.log(`📊 Message Status: ${statusText}`)

        if (status === 2) {
          console.log('\n✅ Message delivered successfully to Hedera!')
          break
        } else if (status === 3) {
          console.log('\n❌ Message delivery failed')
          break
        }
      }
    } catch (error) {
      console.log(`   Attempt ${attempts + 1}/${maxAttempts}: Status not available yet...`)
    }

    attempts++
    if (attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, pollInterval))
    }
  }

  console.log('\n═══════════════════════════════════════════════════════════')
  console.log('Monitoring Links')
  console.log('═══════════════════════════════════════════════════════════\n')
  console.log(`🔍 Sepolia Transaction:`)
  console.log(`   https://sepolia.etherscan.io/tx/${txHash}\n`)
  console.log(`🔍 CCIP Explorer:`)
  console.log(`   https://ccip.chain.link/msg/${messageId}\n`)
  console.log('═══════════════════════════════════════════════════════════\n')
  console.log('✅ Demo completed!')
}

main().catch((error) => {
  console.error('❌ Error:', error)
  process.exit(1)
})
