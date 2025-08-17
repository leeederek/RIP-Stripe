// Import environment variables
import "dotenv/config";
import { createWalletClient, http, encodeFunctionData } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sepolia, baseSepolia } from "viem/chains";
import axios from "axios";

// ============ Configuration Constants ============

// Authentication
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const account = privateKeyToAccount(`${PRIVATE_KEY}`);

// Contract Addresses
const ETHEREUM_SEPOLIA_USDC = "0x1c7d4b196cb0c7b01d743fbc6116a902379c7238";
const ETHEREUM_SEPOLIA_TOKEN_MESSENGER =
  "0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5";
const BASE_SEPOLIA_MESSAGE_TRANSMITTER =
  "0x7865fAfC2db2093669d92c0F33AeEF291086BEFD";

// Transfer Parameters
const DESTINATION_ADDRESS = "0xf59dA181591dbB122A894372C6E44cC079A7Bb3F"; // Address to receive minted tokens on destination chain
const AMOUNT = 1_000_000n; // Set transfer amount in 10^6 subunits (1 USDC; change as needed)

// Bytes32 Formatted Parameters
const DESTINATION_ADDRESS_BYTES32 = `0x000000000000000000000000${DESTINATION_ADDRESS.slice(2)}`; // Destination address in bytes32 format

// Chain-specific Parameters
const ETHEREUM_SEPOLIA_DOMAIN = 0; // Source domain ID for Ethereum Sepolia testnet
const BASE_SEPOLIA_DOMAIN = 6; // Destination domain ID for Base Sepolia testnet


// Set up wallet clients
const sepoliaClient = createWalletClient({
    chain: sepolia,
    transport: http(),
    account,
  });
  const baseSepoliaClient = createWalletClient({
    chain: baseSepolia,
    transport: http(),
    account,
  });


  async function approveUSDC() {
    console.log("Approving USDC transfer...");
    const approveTx = await sepoliaClient.sendTransaction({
      to: ETHEREUM_SEPOLIA_USDC,
      data: encodeFunctionData({
        abi: [
          {
            type: "function",
            name: "approve",
            stateMutability: "nonpayable",
            inputs: [
              { name: "spender", type: "address" },
              { name: "amount", type: "uint256" },
            ],
            outputs: [{ name: "", type: "bool" }],
          },
        ],
        functionName: "approve",
        args: [ETHEREUM_SEPOLIA_TOKEN_MESSENGER, 10_000_000_000n], // Set max allowance in 10^6 subunits (10,000 USDC; change as needed)
      }),
    });
    console.log(`USDC Approval Tx: ${approveTx}`);
  }

  async function burnUSDC() {
    console.log("Burning USDC on Ethereum Sepolia...");
    const burnTx = await sepoliaClient.sendTransaction({
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
    console.log(`Burn Tx: ${burnTx}`);
    return burnTx;
  }


async function retrieveAttestation(transactionHash) {
    console.log("Retrieving attestation...");
    const url = `https://iris-api-sandbox.circle.com/v2/messages/${ETHEREUM_SEPOLIA_DOMAIN}?transactionHash=${transactionHash}`;
    while (true) {
      try {
        const response = await axios.get(url);
        if (response.status === 404) {
          console.log("Waiting for attestation...");
        }
        if (response.data?.messages?.[0]?.status === "complete") {
          console.log("Attestation retrieved successfully!");
          return response.data.messages[0];
        }
        console.log("Waiting for attestation...");
        await new Promise((resolve) => setTimeout(resolve, 5000));
      } catch (error) {
        console.error("Error fetching attestation:", error.message);
        await new Promise((resolve) => setTimeout(resolve, 5000));
      }
    }
  }
  async function mintUSDC(attestation) {
    console.log("Minting USDC on Base Sepolia...");
    const mintTx = await baseSepoliaClient.sendTransaction({
      to: BASE_SEPOLIA_MESSAGE_TRANSMITTER,
      data: encodeFunctionData({
        abi: [
          {
            type: "function",
            name: "receiveMessage",
            stateMutability: "nonpayable",
            inputs: [
              { name: "message", type: "bytes" },
              { name: "attestation", type: "bytes" },
            ],
            outputs: [],
          },
        ],
        functionName: "receiveMessage",
        args: [attestation.message, attestation.attestation],
      }),
    });
    console.log(`Mint Tx: ${mintTx}`);
  }


async function main() {
    await approveUSDC();
    const burnTx = await burnUSDC();
    const attestation = await retrieveAttestation(burnTx);
    await mintUSDC(attestation);
    console.log("USDC transfer completed!");
  }
  
  main().catch(console.error);