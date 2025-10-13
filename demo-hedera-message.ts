/**
 * CCIP Demo: Send Message from Hedera Testnet -> Ethereum Sepolia
 *
 * This demo sends a cross-chain message (no token transfer) and pays fee in HBAR
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

  console.log('🚀 CCIP Demo: Send Message from Hedera -> Sepolia\n')

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
  console.log('STEP 1: Check Balance')
  console.log('═══════════════════════════════════════════════════════════\n')

  const balance = await hederaPublicClient.getBalance({ address: account.address })
  console.log(`HBAR Balance: ${Number(balance) / 1e18} HBAR\n`)

  if (balance < parseEther('0.1')) {
    console.log('⚠️  Low balance! You may need more HBAR.')
    console.log('   Get HBAR from: https://portal.hedera.com/faucet\n')
  }

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 2: Check LINK Balance & Approve')
  console.log('═══════════════════════════════════════════════════════════\n')

  // Check LINK balance
  const linkBalance = await hederaPublicClient.readContract({
    address: HEDERA_CONFIG.linkToken,
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

  console.log(`LINK Balance: ${Number(linkBalance) / 1e18} LINK\n`)

  if (linkBalance < BigInt(1e18)) {
    console.log('⚠️  Low LINK balance! You need LINK to pay fees.')
    console.log('   Get LINK from: https://faucets.chain.link/hedera-testnet\n')
  }

  // Approve LINK for fees
  console.log('⏳ Approving LINK for CCIP fees...')
  const approvalAmount = BigInt(1e18) // 1 LINK

  const allowance = await ccipClient.getAllowance({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    tokenAddress: HEDERA_CONFIG.linkToken,
    account: account.address,
  })

  if (allowance < approvalAmount) {
    const { txHash } = await ccipClient.approveRouter({
      client: hederaWalletClient,
      routerAddress: HEDERA_CONFIG.routerAddress,
      tokenAddress: HEDERA_CONFIG.linkToken,
      amount: approvalAmount,
      waitForReceipt: true,
    })
    console.log(`✅ Approved LINK: ${txHash}\n`)
  } else {
    console.log(`✅ LINK already approved\n`)
  }

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 3: Get Message Fee')
  console.log('═══════════════════════════════════════════════════════════\n')

  const message = 'Hello from Hedera via CCIP! 🚀'
  console.log(`Message: "${message}"\n`)

  console.log('⏳ Calculating fee (paying in LINK)...')

  const fee = await ccipClient.getFee({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationAccount: account.address,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    amount: 0n,
    tokenAddress: HEDERA_CONFIG.linkToken,
    message,
    feeTokenAddress: HEDERA_CONFIG.linkToken, // Pay fee in LINK
  })

  console.log(`\nMessage fee: ${Number(fee) / 1e18} LINK\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 4: Send Cross-Chain Message')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Sending message via CCIP...')
  console.log(`   From: Hedera Testnet`)
  console.log(`   To: Ethereum Sepolia`)
  console.log(`   Destination: ${account.address}`)
  console.log(`   Message: "${message}"`)
  console.log(`   Fee payment: ${Number(fee) / 1e18} LINK\n`)

  const { txHash, messageId, txReceipt } = await ccipClient.sendCCIPMessage({
    client: hederaWalletClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    destinationAccount: account.address,
    message,
    feeTokenAddress: HEDERA_CONFIG.linkToken, // Pay fee in LINK
  })

  console.log(`✅ Message sent!`)
  console.log(`   Transaction hash: ${txHash}`)
  console.log(`   Message ID: ${messageId}`)
  console.log(`   Block number: ${txReceipt.blockNumber}\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('STEP 5: Monitor Message Status')
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
