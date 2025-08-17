#!/bin/bash

# Configuration
CONTRACT_ADDRESS="0x22862546E1004054E51a345Ab58De18258090c63"
RPC_URL="https://arb-sepolia.g.alchemy.com/v2/z4V_mDz2QeCcoZEI-l67r2IbF58OlxqH"
PRIVATE_KEY="0xbc35ab21dd0f46d5f76db35fd6dcdbe906e1c0606ef1b85f59e81d5c4b5dd2b3"

# Token addresses
USDC="0x7197cba866D739d20228321467F6BBC6cA676A09"
USDT="0x1f71B914e2A92052f7e0A5B1dB7f8b8fe209D5F3"
PYUSD="0xF0B61d1c7ed86a1d1b2E1Cf7a19f0AF0F783b3F3"
USDe="0x8786aB4F9559D7A86890a3a3d9e4d0841C42EbCD"

echo "=== Adding Liquidity to OrbitalPool ==="
echo "Contract: $CONTRACT_ADDRESS"
echo ""

# Step 1: Check current balances
echo "=== Checking Token Balances ==="
echo "USDC Balance:"
cast call $USDC "balanceOf(address)(uint256)" $(cast wallet address --private-key $PRIVATE_KEY) --rpc-url $RPC_URL

echo "USDT Balance:"
cast call $USDT "balanceOf(address)(uint256)" $(cast wallet address --private-key $PRIVATE_KEY) --rpc-url $RPC_URL

echo "PYUSD Balance:"
cast call $PYUSD "balanceOf(address)(uint256)" $(cast wallet address --private-key $PRIVATE_KEY) --rpc-url $RPC_URL

echo "USDe Balance:"
cast call $USDe "balanceOf(address)(uint256)" $(cast wallet address --private-key $PRIVATE_KEY) --rpc-url $RPC_URL

echo ""

# Step 2: Approve tokens (if needed)
echo "=== Approving Tokens ==="
AMOUNT_TO_APPROVE="1000000000000000000000000" # 1M tokens (with 18 decimals)

echo "Approving USDC..."
cast send $USDC "approve(address,uint256)" $CONTRACT_ADDRESS $AMOUNT_TO_APPROVE \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 100000

echo "Approving USDT..."
cast send $USDT "approve(address,uint256)" $CONTRACT_ADDRESS $AMOUNT_TO_APPROVE \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 100000

echo "Approving PYUSD..."
cast send $PYUSD "approve(address,uint256)" $CONTRACT_ADDRESS $AMOUNT_TO_APPROVE \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 100000

echo "Approving USDe..."
cast send $USDe "approve(address,uint256)" $CONTRACT_ADDRESS $AMOUNT_TO_APPROVE \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 100000

echo ""

# Step 3: Add liquidity
echo "=== Adding Liquidity ==="
# Adding 1000 tokens of each (with appropriate decimals)
# Most stablecoins use 6 or 18 decimals, let's use 1000 * 10^6 = 1000000000

LIQUIDITY_AMOUNTS="[1000000000,1000000000,1000000000,1000000000]" # 1000 tokens each (6 decimals)
PLANE_CONSTANT="500000000" # Roughly 50% of the radius for concentrated liquidity

echo "Adding liquidity with amounts: $LIQUIDITY_AMOUNTS"
echo "Plane constant: $PLANE_CONSTANT"

cast send $CONTRACT_ADDRESS "addLiquidity(uint256[],uint256)" \
  "$LIQUIDITY_AMOUNTS" $PLANE_CONSTANT \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 500000

echo ""

# Step 4: Check pool state after adding liquidity
echo "=== Pool State After Adding Liquidity ==="
echo "Pool Reserves:"
cast call $CONTRACT_ADDRESS "getReserves()(uint256[])" --rpc-url $RPC_URL

echo "Number of ticks:"
cast call $CONTRACT_ADDRESS "ticks(uint256)" 0 --rpc-url $RPC_URL 2>/dev/null && echo "Tick 0 exists" || echo "No ticks found"

echo ""
echo "✅ Liquidity addition complete!"