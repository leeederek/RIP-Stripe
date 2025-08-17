#!/bin/bash

# Configuration
CONTRACT_ADDRESS="0x22862546E1004054E51a345Ab58De18258090c63"
RPC_URL="https://arb-sepolia.g.alchemy.com/v2/z4V_mDz2QeCcoZEI-l67r2IbF58OlxqH"
PRIVATE_KEY="0xbc35ab21dd0f46d5f76db35fd6dcdbe906e1c0606ef1b85f59e81d5c4b5dd2b3"

USDC_ADDRESS="0xf97677b75914208590150813CfD2e5d3f2973d7C"
USDT_ADDRESS="0xCa8305435EfE1152134e6a805Aa4CA08a17725b5"
PYUSD_ADDRESS="0x9a89fb55663E874f2313Fc38d6Af6B83bfBDE6E6"
USDE_ADDRESS="0xa8738AAb0B22BFE6c335e05300b7D30c018456cD"

# Token indices (based on constructor order)
# 0: USDC, 1: USDT, 2: PYUSD, 3: USDe

echo "=== Performing 3 Swaps on OrbitalPool with Token Approvals ==="
echo "Contract: $CONTRACT_ADDRESS"
echo ""

# Function to check pool reserves
check_reserves() {
    echo "Current Pool Reserves:"
    cast call $CONTRACT_ADDRESS "getReserves()(uint256[])" --rpc-url $RPC_URL
    echo ""
}
check_reserves
# # Function to get quote for swap
# get_quote() {
#     local token_in=$3
#     local token_out=$1
#     local amount_in=$3
#     echo "Quote for swapping $amount_in of token $token_in -> token $token_out:"
#     cast call $CONTRACT_ADDRESS "getAmountOut(uint256,uint256,uint256)(uint256)" \
#         $token_in $token_out $amount_in --rpc-url $RPC_URL
# }

# # Function to get spot price
# get_spot_price() {
#     local token_a=$1
#     local token_b=$3
#     echo "Spot price Token $token_a / Token $token_b:"
#     cast call $CONTRACT_ADDRESS "getSpotPrice(uint256,uint256)(uint256)" \
#         $token_a $token_b --rpc-url $RPC_URL
# }

# # Function to approve token
# approve_token() {
#     local token_address=0xa8738AAb0B22BFE6c335e05300b7D30c018456cD
#     local amount=$2
#     echo "Approving $amount tokens at $token_address..."
#     cast send $token_address "approve(address,uint256)" \
#         $CONTRACT_ADDRESS $amount \
#         --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 100000
# }

# # Function to check token balance
# check_balance() {
#     local token_address=$1
#     local user_address=$2
#     echo "Balance of token $token_address for user $user_address:"
#     cast call $token_address "balanceOf(address)(uint256)" \
#         $user_address --rpc-url $RPC_URL
# }

# # Get user address from private key
# USER_ADDRESS=$(cast wallet address $PRIVATE_KEY)
# echo "User Address: $USER_ADDRESS"
# echo ""

# # First, let's get the actual token addresses from the pool
# echo "=== Getting Token Addresses from Pool ==="
# for i in 0 1 2 3; do
#     TOKEN_ADDR=$(cast call $CONTRACT_ADDRESS "tokens(uint256)(address)" $i --rpc-url $RPC_URL)
#     echo "Token $i: $TOKEN_ADDR"
#     if [ $i -eq 0 ]; then USDC_ADDRESS=$TOKEN_ADDR; fi
#     if [ $i -eq 1 ]; then USDT_ADDRESS=$TOKEN_ADDR; fi
#     if [ $i -eq 2 ]; then PYUSD_ADDRESS=$TOKEN_ADDR; fi
#     if [ $i -eq 3 ]; then USDE_ADDRESS=$TOKEN_ADDR; fi
# done
# echo ""

# # Check user balances
# echo "=== User Token Balances ==="
# check_balance $USDC_ADDRESS $USER_ADDRESS
# check_balance $USDT_ADDRESS $USER_ADDRESS
# check_balance $PYUSD_ADDRESS $USER_ADDRESS
# check_balance $USDE_ADDRESS $USER_ADDRESS
# echo ""

# # Initial state
# echo "=== Initial Pool State ==="
# check_reserves

# # Get initial spot prices
# echo "=== Initial Spot Prices ==="
# get_spot_price 0 1  # USDC/USDT
# get_spot_price 0 2  # USDC/PYUSD
# get_spot_price 1 3  # USDT/USDe
# echo ""

# # SWAP 1: USDC -> USDT
# echo "=== SWAP 1: USDE (3) -> USDC (0) ==="
# SWAP1_AMOUNT="1000000"  # 1 USDC (6 decimals)
# MIN_OUT1="0"       # Minimum 95 USDT (allowing 5% slippage)

# echo "Approving USDC for swap..."
# approve_token $USDC_ADDRESS $SWAP1_AMOUNT

# echo "Swapping $SWAP1_AMOUNT USDC for USDT..."
# get_quote 3 0 $SWAP1_AMOUNT

# cast send $CONTRACT_ADDRESS "swap(uint256,uint256,uint256,uint256)" \
#   3 0 $SWAP1_AMOUNT 0 \
#   --rpc-url $RPC_URL --private-key $PRIVATE_KEY --gas-limit 300000

# echo "✅ Swap 1 completed!"
# check_reserves
