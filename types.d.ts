// Type declarations to resolve viem and CCIP SDK compatibility issues
declare module "@chainlink/ccip-js" {
  import type { PublicClient, WalletClient } from "viem";

  // Override the Client type to accept viem clients
  interface CCIPClient {
    getSupportedFeeTokens(params: {
      client: any;
      routerAddress: string;
      destinationChainSelector: string;
    }): Promise<string[]>;
    getFee(params: {
      client: any;
      routerAddress: string;
      destinationAccount: string;
      destinationChainSelector: string;
      amount?: bigint;
      tokenAddress?: string;
      message?: string;
      feeTokenAddress?: string;
    }): Promise<bigint>;
    getAllowance(params: {
      client: any;
      routerAddress: string;
      tokenAddress: string;
      account: string;
    }): Promise<bigint>;
    approveRouter(params: {
      client: any;
      routerAddress: string;
      tokenAddress: string;
      amount: bigint;
      waitForReceipt?: boolean;
    }): Promise<{ txHash: string }>;
    sendCCIPMessage(params: {
      client: any;
      routerAddress: string;
      destinationChainSelector: string;
      destinationAccount: string;
      message?: string;
      feeTokenAddress?: string;
      writeContractParameters?: any;
    }): Promise<{ txHash: string; messageId: string; txReceipt: any }>;
    getTransferStatus(params: {
      client: any;
      destinationRouterAddress: string;
      sourceChainSelector: string;
      messageId: string;
    }): Promise<number | null>;
  }

  export function createClient(): CCIPClient;
}
