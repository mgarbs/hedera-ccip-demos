/**
 * CCIP Demo: Hedera Testnet -> Ethereum Sepolia
 *
 * This demo shows how to transfer tokens cross-chain using CCIP JavaScript SDK
 */

import * as CCIP from '@chainlink/ccip-js'
import { createPublicClient, createWalletClient, http, parseEther } from 'viem'
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

// CCIP Configuration for Hedera Testnet
const HEDERA_CONFIG = {
  routerAddress: '0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4' as `0x${string}`,
  chainSelector: '222782988166878823',
  linkToken: '0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6' as `0x${string}`,
  whbarToken: '0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed' as `0x${string}`,
}

// CCIP Configuration for Sepolia
const SEPOLIA_CONFIG = {
  routerAddress: '0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59' as `0x${string}`,
  chainSelector: '16015286601757825753',
  linkToken: '0x779877A7B0D9E8603169DdbD7836e478b4624789' as `0x${string}`,
}

async function main() {
  // Check for private key
  let privateKey = process.env.PRIVATE_KEY
  if (!privateKey) {
    console.error('❌ Error: PRIVATE_KEY environment variable is required')
    console.log('\nSet it with: export PRIVATE_KEY=0x...')
    console.exit(1)
  }

  // Add 0x prefix if not present
  if (!privateKey.startsWith('0x')) {
    privateKey = '0x' + privateKey
  }

  console.log('🚀 CCIP Demo: Hedera Testnet -> Ethereum Sepolia\n')

  // Create account from private key
  const account = privateKeyToAccount(privateKey as `0x${string}`)
  console.log(`📝 Using account: ${account.address}\n`)

  // Initialize CCIP client
  const ccipClient = CCIP.createClient()

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

  // Create Sepolia public client (for checking status later)
  const sepoliaPublicClient = createPublicClient({
    chain: sepolia,
    transport: http(),
  })

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 1: Check Token Support')
  console.log('═══════════════════════════════════════════════════════════\n')

  const isLinkSupported = await ccipClient.isTokenSupported({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    tokenAddress: HEDERA_CONFIG.linkToken,
  })

  console.log(`LINK Token supported on Sepolia lane: ${isLinkSupported ? '✅' : '❌'}`)

  if (!isLinkSupported) {
    console.log('\n❌ LINK token not supported for this lane')
    process.exit(1)
  }

  console.log('\n═══════════════════════════════════════════════════════════')
  console.log('STEP 2: Check Allowance & Approve Router')
  console.log('═══════════════════════════════════════════════════════════\n')

  const transferAmount = parseEther('0.01') // 0.01 LINK
  const destinationAddress = account.address // Send to ourselves

  const allowance = await ccipClient.getAllowance({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    tokenAddress: HEDERA_CONFIG.linkToken,
    account: account.address,
  })

  console.log(`Current allowance: ${allowance} wei`)
  console.log(`Transfer amount: ${transferAmount} wei (0.01 LINK)\n`)

  if (allowance < transferAmount) {
    console.log('⏳ Approving router to spend tokens...')
    const { txHash } = await ccipClient.approveRouter({
      client: hederaWalletClient,
      routerAddress: HEDERA_CONFIG.routerAddress,
      tokenAddress: HEDERA_CONFIG.linkToken,
      amount: transferAmount * 2n, // Approve 2x for future transfers
      waitForReceipt: true,
    })
    console.log(`✅ Approval transaction: ${txHash}\n`)
  } else {
    console.log('✅ Sufficient allowance already approved\n')
  }

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 3: Get Transfer Fee')
  console.log('═══════════════════════════════════════════════════════════\n')

  const fee = await ccipClient.getFee({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    tokenAddress: HEDERA_CONFIG.linkToken,
    amount: transferAmount,
    destinationAccount: destinationAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    // Not specifying feeTokenAddress means we'll pay in native HBAR
  })

  console.log(`Transfer fee (in HBAR): ${fee} wei`)
  console.log(`Transfer fee (human): ${Number(fee) / 1e18} HBAR\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 4: Get Supported Fee Tokens')
  console.log('═══════════════════════════════════════════════════════════\n')

  const supportedFeeTokens = await ccipClient.getSupportedFeeTokens({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
  })

  console.log('Supported fee tokens:')
  supportedFeeTokens.forEach((token, i) => {
    console.log(`  ${i + 1}. ${token}`)
  })
  console.log('')

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 5: Get Rate Limits')
  console.log('═══════════════════════════════════════════════════════════\n')

  const laneRateLimits = await ccipClient.getLaneRateRefillLimits({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
  })

  console.log('Lane rate limits:')
  console.log(`  Enabled: ${laneRateLimits.isEnabled}`)
  console.log(`  Capacity: ${laneRateLimits.capacity}`)
  console.log(`  Tokens: ${laneRateLimits.tokens}`)
  console.log(`  Rate: ${laneRateLimits.rate}/sec\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 6: Execute Cross-Chain Transfer')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Initiating cross-chain transfer...')
  console.log(`   From: Hedera Testnet`)
  console.log(`   To: Ethereum Sepolia`)
  console.log(`   Amount: 0.01 LINK`)
  console.log(`   Destination: ${destinationAddress}\n`)

  const { txHash, messageId, txReceipt } = await ccipClient.transferTokens({
    client: hederaWalletClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    amount: transferAmount,
    destinationAccount: destinationAddress,
    tokenAddress: HEDERA_CONFIG.linkToken,
    // Paying fee in native HBAR (not specifying feeTokenAddress)
  })

  console.log(`✅ Transfer initiated!`)
  console.log(`   Transaction hash: ${txHash}`)
  console.log(`   Message ID: ${messageId}`)
  console.log(`   Block number: ${txReceipt.blockNumber}\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 7: Monitor Transfer Status')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Checking transfer status on Sepolia...')
  console.log('   (This may take several minutes for cross-chain finality)\n')

  // Poll for status
  let attempts = 0
  const maxAttempts = 20
  const pollInterval = 15000 // 15 seconds

  while (attempts < maxAttempts) {
    try {
      const status = await ccipClient.getTransferStatus({
        client: sepoliaPublicClient,
        destinationRouterAddress: SEPOLIA_CONFIG.routerAddress,
        sourceChainSelector: HEDERA_CONFIG.chainSelector,
        messageId,
      })

      if (status !== null) {
        const statusText = ['Untouched', 'InProgress', 'Success', 'Failure'][status]
        console.log(`📊 Transfer Status: ${statusText}`)

        if (status === 2) {
          console.log('\n✅ Transfer completed successfully!')
          break
        } else if (status === 3) {
          console.log('\n❌ Transfer failed')
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
  console.log(`🔍 Hedera Transaction:`)
  console.log(`   https://hashscan.io/testnet/transaction/${txHash}\n`)
  console.log(`🔍 CCIP Explorer:`)
  console.log(`   https://ccip.chain.link/msg/${messageId}\n`)
  console.log('═══════════════════════════════════════════════════════════\n')
  console.log('✅ Demo completed!')
}

main().catch((error) => {
  console.error('❌ Error:', error)
  process.exit(1)
})
