// @ts-nocheck
/**
 * CCIP Read-Only Demo: Hedera Testnet Configuration
 *
 * This demo shows how to query CCIP configuration without requiring funds or private keys
 */

import * as CCIP from '@chainlink/ccip-js'
import { createPublicClient, http } from 'viem'

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
  chainSelector: '16015286601757825753',
  linkToken: '0x779877A7B0D9E8603169DdbD7836e478b4624789' as `0x${string}`,
}

async function main() {
  console.log('🔍 CCIP Read-Only Demo: Hedera Testnet Configuration\n')
  console.log('This demo queries CCIP configuration without requiring funds or transactions.\n')

  // Initialize CCIP client
  const ccipClient = CCIP.createClient()

  // Create Hedera public client
  const hederaPublicClient = createPublicClient({
    chain: hederaTestnet,
    transport: http(),
  })

  console.log('═══════════════════════════════════════════════════════════')
  console.log('Network Information')
  console.log('═══════════════════════════════════════════════════════════\n')
  console.log(`Chain: ${hederaTestnet.name}`)
  console.log(`Chain ID: ${hederaTestnet.id}`)
  console.log(`RPC: ${hederaTestnet.rpcUrls.default.http[0]}`)
  console.log(`CCIP Router: ${HEDERA_CONFIG.routerAddress}`)
  console.log(`Chain Selector: ${HEDERA_CONFIG.chainSelector}\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('Token Support Check')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Checking if LINK is supported on Hedera→Sepolia lane...')
  const isLinkSupported = await ccipClient.isTokenSupported({
    // @ts-ignore
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    tokenAddress: HEDERA_CONFIG.linkToken,
  })

  console.log(`\nLINK Token (${HEDERA_CONFIG.linkToken}):`)
  console.log(`  Supported: ${isLinkSupported ? '✅ Yes' : '❌ No'}\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('Supported Fee Tokens')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Fetching supported fee tokens for Hedera→Sepolia...')
  const supportedFeeTokens = await ccipClient.getSupportedFeeTokens({
    // @ts-ignore
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
  })

  console.log(`\nYou can pay CCIP fees with any of these ${supportedFeeTokens.length} tokens:\n`)
  supportedFeeTokens.forEach((token, i) => {
    const tokenName = token === HEDERA_CONFIG.linkToken
      ? 'LINK'
      : token === HEDERA_CONFIG.whbarToken
      ? 'WHBAR'
      : 'Unknown'
    console.log(`  ${i + 1}. ${token} (${tokenName})`)
  })
  console.log(`\nOr use native HBAR to pay fees.\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('OnRamp Address')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Fetching OnRamp address for Hedera→Sepolia...')
  const onRampAddress = await ccipClient.getOnRampAddress({
    // @ts-ignore
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
  })

  console.log(`\nOnRamp contract: ${onRampAddress}`)
  console.log(`(This is the entry point for cross-chain transfers to Sepolia)\n`)

  console.log('═══════════════════════════════════════════════════════════')
  console.log('Rate Limits')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Fetching lane rate limits...')
  const laneRateLimits = await ccipClient.getLaneRateRefillLimits({
    // @ts-ignore
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
  })

  console.log('\nLane Rate Limiting (prevents spam/congestion):')
  console.log(`  Enabled: ${laneRateLimits.isEnabled ? '✅ Yes' : '❌ No'}`)
  console.log(`  Capacity: ${laneRateLimits.capacity} wei`)
  console.log(`  Current tokens: ${laneRateLimits.tokens} wei`)
  console.log(`  Refill rate: ${laneRateLimits.rate} wei/second`)
  console.log(`  Last updated: ${new Date(laneRateLimits.lastUpdated * 1000).toISOString()}\n`)

  console.log('⏳ Fetching LINK token rate limits...')
  try {
    const tokenRateLimits = await ccipClient.getTokenRateLimitByLane({
      // @ts-ignore
    client: hederaPublicClient,
      routerAddress: HEDERA_CONFIG.routerAddress,
      supportedTokenAddress: HEDERA_CONFIG.linkToken,
      destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    })

    console.log('\nLINK Token Rate Limiting:')
    console.log(`  Enabled: ${tokenRateLimits.isEnabled ? '✅ Yes' : '❌ No'}`)
    console.log(`  Capacity: ${tokenRateLimits.capacity} wei`)
    console.log(`  Current tokens: ${tokenRateLimits.tokens} wei`)
    console.log(`  Refill rate: ${tokenRateLimits.rate} wei/second`)
    console.log(`  Last updated: ${new Date(tokenRateLimits.lastUpdated * 1000).toISOString()}\n`)
  } catch (error) {
    console.log('\n⚠️  Could not fetch LINK token rate limits')
    console.log(`   Error: ${(error as Error).message}`)
    console.log('   (Token pool may not be fully configured yet)\n')
  }

  console.log('═══════════════════════════════════════════════════════════')
  console.log('Token Admin Registry')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('⏳ Fetching Token Admin Registry address...')
  try {
    const tokenAdminRegistry = await ccipClient.getTokenAdminRegistry({
      // @ts-ignore
    client: hederaPublicClient,
      routerAddress: HEDERA_CONFIG.routerAddress,
      destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
      tokenAddress: HEDERA_CONFIG.linkToken,
    })

    console.log(`\nToken Admin Registry: ${tokenAdminRegistry}`)
    console.log(`(This contract manages token configurations for CCIP)\n`)
  } catch (error) {
    console.log('\n⚠️  Could not fetch Token Admin Registry')
    console.log(`   Error: ${(error as Error).message}\n`)
  }

  console.log('═══════════════════════════════════════════════════════════')
  console.log('Summary')
  console.log('═══════════════════════════════════════════════════════════\n')

  console.log('✅ Successfully queried CCIP configuration!')
  console.log('\nKey Findings:')
  console.log(`  • LINK is ${isLinkSupported ? 'supported' : 'not supported'} on Hedera→Sepolia lane`)
  console.log(`  • ${supportedFeeTokens.length} fee token options available`)
  console.log(`  • Rate limiting is ${laneRateLimits.isEnabled ? 'active' : 'inactive'}`)
  console.log(`  • OnRamp contract: ${onRampAddress.slice(0, 10)}...`)
  console.log('\nNext Steps:')
  console.log(`  • To execute a transfer, run: npx tsx demo-hedera-sepolia.ts`)
  console.log(`  • Make sure you have HBAR and LINK in your wallet`)
  console.log(`  • Set your PRIVATE_KEY environment variable`)
  console.log('\n═══════════════════════════════════════════════════════════\n')
}

main().catch((error) => {
  console.error('❌ Error:', error)
  process.exit(1)
})
