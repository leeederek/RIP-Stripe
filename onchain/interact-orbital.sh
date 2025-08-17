#!/bin/bash

# OrbitalPool Contract Address (your deployed contract)
CONTRACT_ADDRESS="0x22862546E1004054E51a345Ab58De18258090c63"
RPC_URL="https://arb-sepolia.g.alchemy.com/v2/z4V_mDz2QeCcoZEI-l67r2IbF58OlxqH"

echo "=== OrbitalPool Contract Interaction ==="
echo "Contract: $CONTRACT_ADDRESS"
echo "Network: Arbitrum Sepolia"
echo ""

# Check basic contract info
echo "=== Basic Contract Info ==="

# Check token count
echo "Token Count:"
cast call $CONTRACT_ADDRESS "tokenCount()(uint256)" --rpc-url $RPC_URL

# Check owner
echo -e "\nOwner:"
cast call $CONTRACT_ADDRESS "owner()(address)" --rpc-url $RPC_URL

# Check swap fee
echo -e "\nSwap Fee (basis points):"
cast call $CONTRACT_ADDRESS "swapFee()(uint256)" --rpc-url $RPC_URL

# Get token addresses
echo -e "\n=== Token Addresses ==="
for i in {0..3}; do
    echo "Token $i:"
    cast call $CONTRACT_ADDRESS "tokens(uint256)(address)" $i --rpc-url $RPC_URL
done

# Get total reserves
echo -e "\n=== Current Pool Reserves ==="
cast call $CONTRACT_ADDRESS "getReserves()(uint256[])" --rpc-url $RPC_URL

# Check number of active ticks
echo -e "\n=== Number of Ticks ==="
cast call $CONTRACT_ADDRESS "ticks(uint256)" 0 --rpc-url $RPC_URL 2>/dev/null || echo "No ticks yet"

echo -e "\n=== Ready for interaction! ==="
echo "To add liquidity or swap, you'll need:"
echo "1. Token approvals for the contract"
echo "2. Sufficient token balances"
echo "3. Your private key for transactions"