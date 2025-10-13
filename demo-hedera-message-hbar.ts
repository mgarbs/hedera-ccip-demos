/**
 * CCIP Demo: Send Message from Hedera Testnet -> Ethereum Sepolia (Pay in HBAR)
 *
 * This demo sends a cross-chain message from Hedera to Sepolia, paying fee in native HBAR
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

// CCIP Configuration
const HEDERA_CONFIG = {
  routerAddress: '0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4' as `0x${string}`,
  chainSelector: '222782988166878823',
  linkToken: '0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6' as `0x${string}`,
  whbarToken: '0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed' as `0x${string}`,
}

const SEPOLIA_CONFIG = {
  routerAddress: '0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59' as `0x${string}`,
  chainSelector: '16015286601757825753',
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

  console.log('🚀 CCIP Demo: Send Message from Hedera -> Sepolia (Pay in HBAR)\n')

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

  // Create Sepolia client for monitoring
  const sepoliaPublicClient = createPublicClient({
    chain: sepolia,
    transport: http(),
  })

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 1: Check WHBAR Balance')
  console.log('═══════════════════════════════════════════════════════════\n')

  // Check WHBAR balance (WHBAR uses 8 decimals)
  const whbarBalance = await hederaPublicClient.readContract({
    address: HEDERA_CONFIG.whbarToken,
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

  if (whbarBalance < BigInt(1e8)) { // Less than 1 WHBAR
    console.log('⚠️  Low WHBAR balance! You need WHBAR to pay fees.')
    console.log('   Run: npx tsx wrap-hbar.ts\n')
  }

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 2: Check Supported Fee Tokens')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Fetching supported fee tokens...')
  const supportedFeeTokens = await ccipClient.getSupportedFeeTokens({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
  })

  console.log(`\nSupported fee tokens (${supportedFeeTokens.length}):\n`)
  supportedFeeTokens.forEach((token, i) => {
    const name = token === HEDERA_CONFIG.linkToken ? 'LINK' : token === HEDERA_CONFIG.whbarToken ? 'WHBAR' : 'Unknown'
    console.log(`  ${i + 1}. ${token} (${name})`)
  })
  console.log(`\n💡 We'll use WHBAR (Wrapped HBAR) for this demo.\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 3: Approve WHBAR for Router')
  console.log('═══════════════════════════════════════════════════════════\n')

  const message = 'Hello from Hedera via CCIP, paid with WHBAR! 💎'
  console.log(`Message: "${message}"\n`)

  //Get fee in WHBAR
  const feeInWhbar = await ccipClient.getFee({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationAccount: account.address,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    amount: 0n,
    message,
    feeTokenAddress: HEDERA_CONFIG.whbarToken,
  })

  console.log(`Message fee: ${Number(feeInWhbar) / 1e8} WHBAR\n`)

  // Check and approve WHBAR
  const allowance = await ccipClient.getAllowance({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    tokenAddress: HEDERA_CONFIG.whbarToken,
    account: account.address,
  })

  if (allowance < feeInWhbar) {
    console.log('⏳ Approving WHBAR for CCIP router...')
    const { txHash } = await ccipClient.approveRouter({
      client: hederaWalletClient,
      routerAddress: HEDERA_CONFIG.routerAddress,
      tokenAddress: HEDERA_CONFIG.whbarToken,
      amount: feeInWhbar * 10n,
      waitForReceipt: true,
    })
    console.log(`✅ Approved WHBAR: ${txHash}\n`)
  } else {
    console.log(`✅ WHBAR already approved\n`)
  }

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 4: Compare Fees')
  console.log('═══════════════════════════════════════════════════════════\n')

  // Compare fee in LINK
  const feeInLink = await ccipClient.getFee({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationAccount: account.address,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    amount: 0n,
    message,
    feeTokenAddress: HEDERA_CONFIG.linkToken,
  })

  console.log(`Fee options:`)
  console.log(`  • Pay in WHBAR: ${Number(feeInWhbar) / 1e8} WHBAR`)
  console.log(`  • Pay in LINK: ${Number(feeInLink) / 1e18} LINK\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 5: Send Cross-Chain Message')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Sending message via CCIP...')
  console.log(`   From: Hedera Testnet`)
  console.log(`   To: Ethereum Sepolia`)
  console.log(`   Destination: ${account.address}`)
  console.log(`   Message: "${message}"`)
  console.log(`   Fee payment: ${Number(feeInWhbar) / 1e8} WHBAR\n`)

  // Use SDK to send message with WHBAR as fee token
  const { txHash, messageId, txReceipt } = await ccipClient.sendCCIPMessage({
    client: hederaWalletClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    destinationAccount: account.address,
    message,
    feeTokenAddress: HEDERA_CONFIG.whbarToken,
  })

  console.log(`✅ Message sent!`)
  console.log(`   Transaction hash: ${txHash}`)
  console.log(`   Message ID: ${messageId}`)
  console.log(`   Block number: ${txReceipt.blockNumber}\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 6: Monitor Message Status')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Checking message status on Sepolia...')
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
        console.log(`📊 Message Status: ${statusText}`)

        if (status === 2) {
          console.log('\n✅ Message delivered successfully!')
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
