#!/bin/bash

echo "🚀 OrbitalPool Demo Script"
echo "=========================="
echo ""

# Check if scripts exist
if [[ ! -f "./add-liquidity.sh" ]] || [[ ! -f "./perform-swaps.sh" ]]; then
    echo "❌ Required scripts not found!"
    echo "Make sure add-liquidity.sh and perform-swaps.sh are in the current directory."
    exit 1
fi

echo "📋 This demo will:"
echo "1. Check your token balances"
echo "2. Approve tokens for the OrbitalPool contract" 
echo "3. Add liquidity to the pool"
echo "4. Perform 3 different swaps:"
echo "   - USDC -> USDT"
echo "   - USDT -> PYUSD"
echo "   - PYUSD -> USDe"
echo ""

read -p "🤔 Do you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Demo cancelled."
    exit 0
fi

echo ""
echo "🏗️  PHASE 1: Adding Liquidity"
echo "=============================="
./add-liquidity.sh

if [ $? -ne 0 ]; then
    echo "❌ Liquidity addition failed. Check your token balances and try again."
    echo ""
    echo "💡 You may need test tokens. Try these faucets:"
    echo "   - Arbitrum Sepolia Faucet: https://faucet.quicknode.com/arbitrum/sepolia"
    echo "   - Or check if these are mintable test tokens"
    exit 1
fi

echo ""
echo "⏳ Waiting 10 seconds for transactions to settle..."
sleep 10

echo ""
echo "💱 PHASE 2: Performing Swaps"
echo "============================="
./perform-swaps.sh

if [ $? -ne 0 ]; then
    echo "❌ Swaps failed. This might be due to insufficient liquidity or slippage."
    exit 1
fi

echo ""
echo "🎉 OrbitalPool Demo Complete!"
echo "=============================="
echo ""
echo "✅ Successfully demonstrated:"
echo "   - Liquidity provision using spherical invariant"
echo "   - Multi-token swaps in 4D space"
echo "   - Orbital AMM's concentrated liquidity mechanics"
echo ""
echo "📊 Check the final pool state with: ./interact-orbital.sh"