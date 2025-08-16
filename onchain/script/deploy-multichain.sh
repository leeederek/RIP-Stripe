#!/bin/bash

# Multi-chain deployment script for OrbitalPool
# Usage: ./deploy-multichain.sh [network1] [network2] ...
# If no networks specified, deploys to all configured networks

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create a .env file with DEPLOYER_PRIVATE_KEY"
    exit 1
fi

# Check if DEPLOYER_PRIVATE_KEY is set
if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo -e "${RED}Error: DEPLOYER_PRIVATE_KEY not set in .env${NC}"
    exit 1
fi

# Default networks to deploy to
DEFAULT_NETWORKS=("sepolia" "mumbai" "arbitrum_sepolia" "optimism_sepolia" "base_sepolia")

# Use provided networks or default
if [ $# -eq 0 ]; then
    NETWORKS=("${DEFAULT_NETWORKS[@]}")
else
    NETWORKS=("$@")
fi

# Create deployments directory if it doesn't exist
mkdir -p deployments

echo -e "${GREEN}Starting multi-chain deployment of OrbitalPool${NC}"
echo "Networks to deploy: ${NETWORKS[@]}"
echo ""

# Function to deploy to a specific network
deploy_to_network() {
    local network=$1
    echo -e "${YELLOW}Deploying to $network...${NC}"
    
    # Run deployment script
    if forge script script/DeployOrbitalPoolMultiChain.s.sol \
        --rpc-url $network \
        --broadcast \
        --verify \
        -vvvv; then
        echo -e "${GREEN}✓ Successfully deployed to $network${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to deploy to $network${NC}"
        return 1
    fi
}

# Deploy to each network
FAILED_DEPLOYMENTS=()
SUCCESSFUL_DEPLOYMENTS=()

for network in "${NETWORKS[@]}"; do
    echo -e "${YELLOW}=====================================${NC}"
    if deploy_to_network "$network"; then
        SUCCESSFUL_DEPLOYMENTS+=("$network")
    else
        FAILED_DEPLOYMENTS+=("$network")
    fi
    echo ""
done

# Summary
echo -e "${YELLOW}=====================================${NC}"
echo -e "${GREEN}Deployment Summary:${NC}"
echo ""

if [ ${#SUCCESSFUL_DEPLOYMENTS[@]} -gt 0 ]; then
    echo -e "${GREEN}Successfully deployed to:${NC}"
    for network in "${SUCCESSFUL_DEPLOYMENTS[@]}"; do
        echo "  ✓ $network"
    done
fi

if [ ${#FAILED_DEPLOYMENTS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed deployments:${NC}"
    for network in "${FAILED_DEPLOYMENTS[@]}"; do
        echo "  ✗ $network"
    done
fi

echo ""
echo "Deployment artifacts saved in: ./deployments/"
echo ""

# Show deployed addresses
if [ ${#SUCCESSFUL_DEPLOYMENTS[@]} -gt 0 ]; then
    echo -e "${GREEN}Deployed contract addresses:${NC}"
    for file in deployments/*.json; do
        if [ -f "$file" ]; then
            echo "  $(basename $file):"
            cat "$file" | jq '.'
            echo ""
        fi
    done
fi