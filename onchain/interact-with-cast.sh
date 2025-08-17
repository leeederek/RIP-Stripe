#!/bin/bash

# OrbitalPool Contract Address on Arbitrum Sepolia
CONTRACT_ADDRESS="0xfb4bf4f71339f659a979d4074e428ba442926708"
RPC_URL="https://sepolia-rollup.arbitrum.io/rpc"

# Get basic contract info
echo "=== Checking Contract Info ==="

# Check tokenCount
echo "Token Count:"
cast call $CONTRACT_ADDRESS "tokenCount()(uint256)" --rpc-url $RPC_URL

# Check total liquidity
echo -e "\nTotal Liquidity:"
cast call $CONTRACT_ADDRESS "totalLiquidity()(uint256)" --rpc-url $RPC_URL

# Get token addresses
echo -e "\n=== Token Addresses ==="
for i in {0..3}; do
    echo "Token $i:"
    cast call $CONTRACT_ADDRESS "tokens(uint256)(address)" $i --rpc-url $RPC_URL
done

# Get token symbols
echo -e "\n=== Token Symbols ==="
for i in {0..3}; do
    echo "Token $i symbol:"
    cast call $CONTRACT_ADDRESS "tokenSymbols(uint256)(string)" $i --rpc-url $RPC_URL
done

# Get total reserves
echo -e "\n=== Total Reserves ==="
cast call $CONTRACT_ADDRESS "getTotalReserves()(uint256[])" --rpc-url $RPC_URL

# Check if pool is initialized
echo -e "\n=== Active Ticks ==="
cast call $CONTRACT_ADDRESS "getActiveTickIds()(uint256[])" --rpc-url $RPC_URL

# Get next tick ID
echo -e "\n=== Next Tick ID ==="
cast call $CONTRACT_ADDRESS "nextTickId()(uint256)" --rpc-url $RPC_URL

# Example: Add liquidity (requires token approvals first)
# cast send $CONTRACT_ADDRESS "addLiquidity(uint256[],uint256,uint256,address)" \
#   "[1000000,1000000,1000000,1000000]" 0 1735689600 $YOUR_ADDRESS \
#   --rpc-url $RPC_URL --private-key $YOUR_PRIVATE_KEY

# Example: Swap tokens (requires token approval first)  
# cast send $CONTRACT_ADDRESS "swap(uint256,uint256,uint256,uint256,address)" \
#   0 1 1000000 900000 $YOUR_ADDRESS \
#   --rpc-url $RPC_URL --private-key $YOUR_PRIVATE_KEY