/**
 * CCIP Demo: Send Message from Hedera Testnet -> Ethereum Sepolia (Pay in HBAR)
 *
 * This demo sends a cross-chain message from Hedera to Sepolia, paying fee in native HBAR
 */

import "dotenv/config";
import * as CCIP from "@chainlink/ccip-js";
import { createPublicClient, createWalletClient, http, parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sepolia } from "viem/chains";

// Custom Hedera testnet chain configuration
const hederaTestnet = {
  id: 296,
  name: "Hedera Testnet",
  network: "hedera-testnet",
  nativeCurrency: {
    decimals: 18,
    name: "HBAR",
    symbol: "HBAR"
  },
  rpcUrls: {
    default: {
      http: ["https://testnet.hashio.io/api"]
    },
    public: {
      http: ["https://testnet.hashio.io/api"]
    }
  },
  blockExplorers: {
    default: { name: "HashScan", url: "https://hashscan.io/testnet" }
  },
  testnet: true
} as const;

// CCIP Configuration
const HEDERA_CONFIG = {
  routerAddress: "0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4" as `0x${string}`,
  chainSelector: "222782988166878823",
  linkToken: "0x90a386d59b9A6a4795a011e8f032Fc21ED6FEFb6" as `0x${string}`,
  whbarToken: "0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed" as `0x${string}`
};

const SEPOLIA_CONFIG = {
  routerAddress: "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59" as `0x${string}`,
  chainSelector: "16015286601757825753"
};

async function main() {
  // Check for private key
  let privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    console.error("❌ Error: PRIVATE_KEY environment variable is required");
    console.log("\nSet it with: export PRIVATE_KEY=0x...");
    process.exit(1);
  }

  // Add 0x prefix if not present
  if (!privateKey.startsWith("0x")) {
    privateKey = "0x" + privateKey;
  }

  console.log(
    "🚀 CCIP Demo: Send Message from Hedera -> Sepolia (Pay in HBAR)\n"
  );

  // Create account from private key
  const account = privateKeyToAccount(privateKey as `0x${string}`);
  console.log(`📝 Using account: ${account.address}\n`);

  // Initialize CCIP client
  const ccipClient = CCIP.createClient();

  // Create Hedera clients
  const hederaPublicClient = createPublicClient({
    chain: hederaTestnet,
    transport: http()
  });

  const hederaWalletClient = createWalletClient({
    account,
    chain: hederaTestnet,
    transport: http()
  });

  // Create Sepolia client for monitoring
  const sepoliaPublicClient = createPublicClient({
    chain: sepolia,
    transport: http()
  });

  console.log("═══════════════════════════════════════════════════════════");
  console.log("STEP 1: Check WHBAR Balance");
  console.log("═══════════════════════════════════════════════════════════\n");

  // Check WHBAR token decimals first
  console.log("⏳ Checking WHBAR token configuration...");
  const whbarDecimals = await hederaPublicClient.readContract({
    address: HEDERA_CONFIG.whbarToken,
    abi: [
      {
        name: "decimals",
        type: "function",
        stateMutability: "view",
        inputs: [],
        outputs: [{ name: "", type: "uint8" }]
      }
    ],
    functionName: "decimals"
  });

  console.log(`WHBAR decimals: ${whbarDecimals}`);
  console.log(`WHBAR address: ${HEDERA_CONFIG.whbarToken}\n`);

  // Check WHBAR balance
  const whbarBalance = await hederaPublicClient.readContract({
    address: HEDERA_CONFIG.whbarToken,
    abi: [
      {
        name: "balanceOf",
        type: "function",
        stateMutability: "view",
        inputs: [{ name: "account", type: "address" }],
        outputs: [{ name: "balance", type: "uint256" }]
      }
    ],
    functionName: "balanceOf",
    args: [account.address]
  });

  console.log(
    `WHBAR Balance: ${
      Number(whbarBalance) / 10 ** Number(whbarDecimals)
    } WHBAR\n`
  );

  if (whbarBalance < BigInt(10 ** Number(whbarDecimals))) {
    // Less than 1 WHBAR
    console.log("⚠️  Low WHBAR balance! You need WHBAR to pay fees.");
    console.log("   Run: npx tsx wrap-hbar.ts\n");
  }

  console.log("═══════════════════════════════════════════════════════════");
  console.log("STEP 2: Check Supported Fee Tokens");
  console.log("═══════════════════════════════════════════════════════════\n");

  console.log("⏳ Fetching supported fee tokens...");
  const supportedFeeTokens = await ccipClient.getSupportedFeeTokens({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector
  });

  console.log(`\nSupported fee tokens (${supportedFeeTokens.length}):\n`);
  supportedFeeTokens.forEach((token, i) => {
    const name =
      token === HEDERA_CONFIG.linkToken
        ? "LINK"
        : token === HEDERA_CONFIG.whbarToken
        ? "WHBAR"
        : "Unknown";
    console.log(`  ${i + 1}. ${token} (${name})`);
  });
  console.log(`\n💡 We'll use WHBAR (Wrapped HBAR) for this demo.\n`);

  console.log("═══════════════════════════════════════════════════════════");
  console.log("STEP 3: Approve WHBAR for Router");
  console.log("═══════════════════════════════════════════════════════════\n");

  const message = "Hello from Hedera via CCIP, paid with WHBAR! 💎";
  console.log(`Message: "${message}"\n`);

  //Get fee in WHBAR
  const feeInWhbar = await ccipClient.getFee({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationAccount: account.address,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    amount: 0n,
    message,
    feeTokenAddress: HEDERA_CONFIG.whbarToken
  });

  // ═══════════════════════════════════════════════════════════════════════════════════════
  // IMPORTANT: Hedera Testnet Fee Calculation
  // ═══════════════════════════════════════════════════════════════════════════════════════
  // The CCIP client automatically scales fees for Hedera by an additional 10 decimals
  // because Hedera has "non-standard decimals" (you'll see this in the log above).
  //
  // To get the actual fee amount:
  // 1. Token has its standard decimals (e.g., WHBAR has 18 decimals)
  // 2. CCIP adds 10 extra decimals for Hedera scaling
  // 3. Total: we need to divide by (token decimals + 10 Hedera scaling decimals)
  // ═══════════════════════════════════════════════════════════════════════════════════════
  const HEDERA_SCALING_DECIMALS = 10;
  const totalWhbarDecimals = Number(whbarDecimals) + HEDERA_SCALING_DECIMALS;
  const actualWhbarFee = Number(feeInWhbar) / 10 ** totalWhbarDecimals;

  console.log(`Message fee: ${actualWhbarFee} WHBAR\n`);

  // Check and approve WHBAR
  const allowance = await ccipClient.getAllowance({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    tokenAddress: HEDERA_CONFIG.whbarToken,
    account: account.address
  });

  if (allowance < feeInWhbar) {
    console.log("⏳ Approving WHBAR for CCIP router...");
    const { txHash } = await ccipClient.approveRouter({
      client: hederaWalletClient,
      routerAddress: HEDERA_CONFIG.routerAddress,
      tokenAddress: HEDERA_CONFIG.whbarToken,
      amount: feeInWhbar * 10n,
      waitForReceipt: true
    });
    console.log(`✅ Approved WHBAR: ${txHash}\n`);
  } else {
    console.log(`✅ WHBAR already approved\n`);
  }

  console.log("═══════════════════════════════════════════════════════════");
  console.log("STEP 4: Compare Fees");
  console.log("═══════════════════════════════════════════════════════════\n");

  console.log("⏳ Calculating fees...");
  // Compare fee in LINK
  const feeInLink = await ccipClient.getFee({
    client: hederaPublicClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationAccount: account.address,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    amount: 0n,
    message,
    feeTokenAddress: HEDERA_CONFIG.linkToken
  });

  const linkDecimals = await hederaPublicClient.readContract({
    address: HEDERA_CONFIG.linkToken,
    abi: [
      {
        name: "decimals",
        type: "function",
        stateMutability: "view",
        inputs: [],
        outputs: [{ name: "", type: "uint8" }]
      }
    ],
    functionName: "decimals"
  });

  console.log(`Fee options:`);

  // Both fees need the same Hedera scaling adjustment (token decimals + 10 scaling decimals)
  const totalLinkDecimals = Number(linkDecimals) + HEDERA_SCALING_DECIMALS;
  const actualLinkFee = Number(feeInLink) / 10 ** totalLinkDecimals;

  console.log(`  • Pay in WHBAR: ${actualWhbarFee} WHBAR`);
  console.log(`  • Pay in LINK: ${actualLinkFee} LINK\n`);

  console.log("═══════════════════════════════════════════════════════════");
  console.log("STEP 5: Send Cross-Chain Message");
  console.log("═══════════════════════════════════════════════════════════\n");

  console.log("⏳ Sending message via CCIP...");
  console.log(`   From: Hedera Testnet`);
  console.log(`   To: Ethereum Sepolia`);
  console.log(`   Destination: ${account.address}`);
  console.log(`   Message: "${message}"`);
  console.log(`   Fee payment: ${actualWhbarFee} WHBAR\n`);

  // Use SDK to send message with WHBAR as fee token
  const { txHash, messageId, txReceipt } = await ccipClient.sendCCIPMessage({
    client: hederaWalletClient,
    routerAddress: HEDERA_CONFIG.routerAddress,
    destinationChainSelector: SEPOLIA_CONFIG.chainSelector,
    destinationAccount: account.address,
    message,
    feeTokenAddress: HEDERA_CONFIG.whbarToken
  });

  console.log(`✅ Message sent!`);
  console.log(`   Transaction hash: ${txHash}`);
  console.log(`   Message ID: ${messageId}`);
  console.log(`   Block number: ${txReceipt.blockNumber}\n`);

  console.log("═══════════════════════════════════════════════════════════");
  console.log("STEP 6: Monitor Message Status");
  console.log("═══════════════════════════════════════════════════════════\n");

  console.log("⏳ Checking message status on Sepolia...");
  console.log("   (This may take several minutes for cross-chain finality)\n");

  // Poll for status
  let attempts = 0;
  const maxAttempts = 20;
  const pollInterval = 15000; // 15 seconds

  while (attempts < maxAttempts) {
    try {
      const status = await ccipClient.getTransferStatus({
        client: sepoliaPublicClient,
        destinationRouterAddress: SEPOLIA_CONFIG.routerAddress,
        sourceChainSelector: HEDERA_CONFIG.chainSelector,
        messageId
      });

      if (status !== null) {
        const statusText = ["Untouched", "InProgress", "Success", "Failure"][
          status
        ];
        console.log(`📊 Message Status: ${statusText}`);

        if (status === 2) {
          console.log("\n✅ Message delivered successfully!");
          break;
        } else if (status === 3) {
          console.log("\n❌ Message delivery failed");
          break;
        }
      }
    } catch (error) {
      console.log(
        `   Attempt ${attempts + 1}/${maxAttempts}: Status not available yet...`
      );
    }

    attempts++;
    if (attempts < maxAttempts) {
      await new Promise((resolve) => setTimeout(resolve, pollInterval));
    }
  }

  console.log("\n═══════════════════════════════════════════════════════════");
  console.log("Monitoring Links");
  console.log("═══════════════════════════════════════════════════════════\n");
  console.log(`🔍 Hedera Transaction:`);
  console.log(`   https://hashscan.io/testnet/transaction/${txHash}\n`);
  console.log(`🔍 CCIP Explorer:`);
  console.log(`   https://ccip.chain.link/msg/${messageId}\n`);
  console.log("═══════════════════════════════════════════════════════════\n");
  console.log("✅ Demo completed!");
}

main().catch((error) => {
  console.error("❌ Error:", error);
  process.exit(1);
});
