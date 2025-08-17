import "dotenv/config";
import { createPublicClient, createWalletClient, http, encodeFunctionData, formatUnits } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sepolia } from "viem/chains";

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const account = privateKeyToAccount(`${PRIVATE_KEY}`);

const ETHEREUM_SEPOLIA_USDC = "0x1c7d4b196cb0c7b01d743fbc6116a902379c7238";
const ETHEREUM_SEPOLIA_TOKEN_MESSENGER = "0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5";

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
});

const walletClient = createWalletClient({
  chain: sepolia,
  transport: http(),
  account,
});

async function checkBalanceAndAllowance() {
  console.log("Checking USDC balance and allowance...");
  
  // Check balance
  const balance = await publicClient.readContract({
    address: ETHEREUM_SEPOLIA_USDC,
    abi: [
      {
        type: "function",
        name: "balanceOf",
        stateMutability: "view",
        inputs: [{ name: "account", type: "address" }],
        outputs: [{ name: "", type: "uint256" }],
      },
    ],
    functionName: "balanceOf",
    args: [account.address],
  });
  
  console.log(`USDC Balance: ${formatUnits(balance, 6)} USDC`);
  
  // Check allowance
  const allowance = await publicClient.readContract({
    address: ETHEREUM_SEPOLIA_USDC,
    abi: [
      {
        type: "function",
        name: "allowance",
        stateMutability: "view",
        inputs: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
        ],
        outputs: [{ name: "", type: "uint256" }],
      },
    ],
    functionName: "allowance",
    args: [account.address, ETHEREUM_SEPOLIA_TOKEN_MESSENGER],
  });
  
  console.log(`USDC Allowance for TokenMessenger: ${formatUnits(allowance, 6)} USDC`);
}

async function testStandardDepositForBurn() {
  console.log("\nTesting standard depositForBurn (5 parameters)...");
  
  const DESTINATION_ADDRESS = "0xf59dA181591dbB122A894372C6E44cC079A7Bb3F";
  const DESTINATION_ADDRESS_BYTES32 = `0x000000000000000000000000${DESTINATION_ADDRESS.slice(2)}`;
  const AMOUNT = 1_000_000n; // 1 USDC
  const BASE_SEPOLIA_DOMAIN = 6;
  
  try {
    const burnTx = await walletClient.sendTransaction({
      to: ETHEREUM_SEPOLIA_TOKEN_MESSENGER,
      data: encodeFunctionData({
        abi: [
          {
            type: "function",
            name: "depositForBurn",
            stateMutability: "nonpayable",
            inputs: [
              { name: "amount", type: "uint256" },
              { name: "destinationDomain", type: "uint32" },
              { name: "mintRecipient", type: "bytes32" },
              { name: "burnToken", type: "address" },
            ],
            outputs: [{ name: "", type: "uint64" }],
          },
        ],
        functionName: "depositForBurn",
        args: [
          AMOUNT,
          BASE_SEPOLIA_DOMAIN,
          DESTINATION_ADDRESS_BYTES32,
          ETHEREUM_SEPOLIA_USDC,
        ],
      }),
    });
    console.log(`Standard depositForBurn Tx: ${burnTx}`);
    return true;
  } catch (error) {
    console.error("Standard depositForBurn failed:", error.message);
    return false;
  }
}

async function main() {
  await checkBalanceAndAllowance();
  await testStandardDepositForBurn();
}

main().catch(console.error);