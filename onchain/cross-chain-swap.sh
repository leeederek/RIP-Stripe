#!/bin/bash

# Configuration for Cross-Chain PUSD -> USDC Swap
# This script demonstrates the complete flow:
# 1. User on ETH Sepolia sends PUSD via OFTAdapter
# 2. OFTAdapter locks PUSD and sends LayerZero message
# 3. Composer on Base Sepolia receives message and mints PUSD
# 4. Composer swaps PUSD -> USDC via Pool B
# 5. User receives USDC on Base Sepolia

# ETH Sepolia Configuration
ETH_SEPOLIA_RPC="https://eth-sepolia.g.alchemy.com/v2/z4V_mDz2QeCcoZEI-l67r2IbF58OlxqH"
ETH_PRIVATE_KEY="0xbc35ab21dd0f46d5f76db35fd6dcdbe906e1c0606ef1b85f59e81d5c4b5dd2b3"
OFT_ADAPTER_ADDRESS="0x0000000000000000000000000000000000000000" # Deploy first
PUSD_ETH_SEPOLIA="0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9"

# Base Sepolia Configuration
BASE_SEPOLIA_RPC="https://sepolia.base.org"
BASE_PRIVATE_KEY="0xbc35ab21dd0f46d5f76db35fd6dcdbe906e1c0606ef1b85f59e81d5c4b5dd2b3"
COMPOSER_ADDRESS="0x0000000000000000000000000000000000000000" # Deploy first
USDC_BASE_SEPOLIA="0x036CBD53842c5426634e7929541ec2318F3DCF7C"

# User addresses (same wallet on both chains)
USER_ETH_SEPOLIA="0xf59dA181591dbB122A894372C6E44cC079A7Bb3F"
USER_BASE_SEPOLIA="0xf59dA181591dbB122A894372C6E44cC079A7Bb3F"

# Amount to swap (in PUSD, 6 decimals)
SWAP_AMOUNT="1000000" # 1 PUSD

echo "=== Cross-Chain PUSD -> USDC Swap Demo ==="
echo ""

echo "Step 1: Check PUSD balance on ETH Sepolia"
echo "User: $USER_ETH_SEPOLIA"
cast call $PUSD_ETH_SEPOLIA "balanceOf(address)(uint256)" $USER_ETH_SEPOLIA --rpc-url $ETH_SEPOLIA_RPC
echo ""

echo "Step 2: Approve PUSD for OFTAdapter on ETH Sepolia"
echo "Amount: $SWAP_AMOUNT"
cast send $PUSD_ETH_SEPOLIA "approve(address,uint256)" \
    $OFT_ADAPTER_ADDRESS $SWAP_AMOUNT \
    --rpc-url $ETH_SEPOLIA_RPC --private-key $ETH_PRIVATE_KEY --gas-limit 100000
echo ""

echo "Step 3: Send PUSD cross-chain via OFTAdapter"
echo "Amount: $SWAP_AMOUNT"
echo "Recipient on Base Sepolia: $USER_BASE_SEPOLIA"
cast send $OFT_ADAPTER_ADDRESS "sendPUSDCrossChain(uint256,address)" \
    $SWAP_AMOUNT $USER_BASE_SEPOLIA \
    --rpc-url $ETH_SEPOLIA_RPC --private-key $ETH_PRIVATE_KEY --gas-limit 500000 \
    --value 0.01ether
echo ""

echo "Step 4: Wait for LayerZero message to be processed..."
echo "This may take a few minutes depending on network conditions"
echo ""

echo "Step 5: Check USDC balance on Base Sepolia"
echo "User: $USER_BASE_SEPOLIA"
cast call $USDC_BASE_SEPOLIA "balanceOf(address)(uint256)" $USER_BASE_SEPOLIA --rpc-url $BASE_SEPOLIA_RPC
echo ""

echo "Step 6: Check transfer status on Composer"
echo "Composer: $COMPOSER_ADDRESS"
# You would need to get the transfer ID from the previous transaction
# cast call $COMPOSER_ADDRESS "getTransfer(bytes32)((address,uint256,uint256,bool))" $TRANSFER_ID --rpc-url $BASE_SEPOLIA_RPC
echo ""

echo "=== Cross-Chain Swap Demo Complete ==="
echo ""
echo "Note: This is a demonstration script. In production:"
echo "- Deploy OFTAdapter and Composer contracts first"
echo "- Set up proper LayerZero endpoints"
echo "- Configure Pool B for actual swaps"
echo "- Add proper error handling and gas estimation"
echo "- Monitor LayerZero message delivery"
