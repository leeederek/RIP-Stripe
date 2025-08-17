#!/bin/bash

# Configuration
CONTRACT_ADDRESS="0x22862546E1004054E51a345Ab58De18258090c63"
RPC_URL="https://arb-sepolia.g.alchemy.com/v2/z4V_mDz2QeCcoZEI-l67r2IbF58OlxqH"
PRIVATE_KEY="0xbc35ab21dd0f46d5f76db35fd6dcdbe906e1c0606ef1b85f59e81d5c4b5dd2b3"

# Token indices (based on constructor order)
# 0: USDC, 1: USDT, 2: PYUSD, 3: USDe

echo "=== Performing 3 Swaps on OrbitalPool ==="
echo "Contract: $CONTRACT_ADDRESS"
echo ""

# Function to check pool reserves
check_reserves() {
    echo "Current Pool Reserves:"
    cast call $CONTRACT_ADDRESS "getReserves()(uint256[])" --rpc-url $RPC_URL
    echo ""
}

# Function to get quote for swap
get_quote() {
    local token_in=$1
    local token_out=$2
    local amount_in=$3
    echo "Quote for swapping $amount_in of token $token_in -> token $token_out:"
    cast call $CONTRACT_ADDRESS "getAmountOut(uint256,uint256,uint256)(uint256)" \
        $token_in $token_out $amount_in --rpc-url $RPC_URL
}

# Function to get spot price
get_spot_price() {
    local token_a=$1
    local token_b=$2
    echo "Spot price Token $token_a / Token $token_b:"
    cast call $CONTRACT_ADDRESS "getSpotPrice(uint256,uint256)(uint256)" \
        $token_a $token_b --rpc-url $RPC_URL
}

# Initial state
echo "=== Initial Pool State ==="
check_reserves

# Get initial spot prices
echo "=== Initial Spot Prices ==="
get_spot_price 0 1  # USDC/USDT
get_spot_price 0 2  # USDC/PYUSD
get_spot_price 1 3  # USDT/USDe
echo ""

# SWAP 1: USDC -> USDT
echo "=== SWAP 1: USDC (0) -> USDT (1) ==="
SWAP1_AMOUNT="100000000"  # 100 USDC (6 decimals)
MIN_OUT1="95000000"       # Minimum 95 USDT (allowing 5% slippage)

echo "Swapping $SWAP1_AMOUNT USDC for USDT..."
get_quote 0 1 $SWAP1_AMOUNT

cast send $CONTRACT_ADDRESS "swap(uint256,uint256,uint256,uint256)" \
  0 1 $SWAP1_AMOUNT $MIN_OUT1 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 300000

echo "✅ Swap 1 completed!"
check_reserves

# SWAP 2: USDT -> PYUSD
echo "=== SWAP 2: USDT (1) -> PYUSD (2) ==="
SWAP2_AMOUNT="50000000"   # 50 USDT
MIN_OUT2="47500000"       # Minimum 47.5 PYUSD

echo "Swapping $SWAP2_AMOUNT USDT for PYUSD..."
get_quote 1 2 $SWAP2_AMOUNT

cast send $CONTRACT_ADDRESS "swap(uint256,uint256,uint256,uint256)" \
  1 2 $SWAP2_AMOUNT $MIN_OUT2 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 300000

echo "✅ Swap 2 completed!"
check_reserves

# SWAP 3: PYUSD -> USDe
echo "=== SWAP 3: PYUSD (2) -> USDe (3) ==="
SWAP3_AMOUNT="25000000"   # 25 PYUSD
MIN_OUT3="23750000"       # Minimum 23.75 USDe

echo "Swapping $SWAP3_AMOUNT PYUSD for USDe..."
get_quote 2 3 $SWAP3_AMOUNT

cast send $CONTRACT_ADDRESS "swap(uint256,uint256,uint256,uint256)" \
  2 3 $SWAP3_AMOUNT $MIN_OUT3 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 300000

echo "✅ Swap 3 completed!"
check_reserves

# Final state
echo "=== Final Pool State ==="
check_reserves

# Final spot prices
echo "=== Final Spot Prices ==="
get_spot_price 0 1  # USDC/USDT
get_spot_price 0 2  # USDC/PYUSD
get_spot_price 1 3  # USDT/USDe
echo ""

echo "🎉 All 3 swaps completed successfully!"
echo ""
echo "Summary:"
echo "1. Swapped USDC -> USDT"
echo "2. Swapped USDT -> PYUSD" 
echo "3. Swapped PYUSD -> USDe"
echo ""
echo "The pool reserves have been updated and prices have changed based on the Orbital AMM's spherical invariant!"