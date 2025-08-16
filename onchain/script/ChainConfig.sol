// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ChainConfig {
    struct TokenConfig {
        address[] tokens;
        string[] symbols;
        address owner;
    }

    function getConfig(uint256 chainId) internal pure returns (TokenConfig memory) {
        TokenConfig memory config;

        if (chainId == 1) {
            // Ethereum Mainnet
            config.tokens = new address[](2);
            config.symbols = new string[](2);
            
            config.tokens[0] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
            config.tokens[1] = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8; // PYUSD
            
            config.symbols[0] = "USDC";
            config.symbols[1] = "PYUSD";
            
            config.owner = address(0); // TODO: Set mainnet owner
            
        } else if (chainId == 11155111) {
            // Sepolia Testnet
            config.tokens = new address[](2);
            config.symbols = new string[](2);
            
            // Sepolia test tokens (you'll need to deploy or find test tokens)
            config.tokens[0] = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // USDC Sepolia
            config.tokens[1] = 0x0000000000000000000000000000000000000000; // TODO: Add PYUSD Sepolia
            
            config.symbols[0] = "USDC";
            config.symbols[1] = "PYUSD";
            
            config.owner = 0xDb25832bA515FD47c6F673eBD98107cdD7632910;
            
        } else if (chainId == 80001) {
            // Mumbai (Polygon Testnet)
            config.tokens = new address[](2);
            config.symbols = new string[](2);
            
            config.tokens[0] = 0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97; // USDC Mumbai
            config.tokens[1] = 0x0000000000000000000000000000000000000000; // TODO: Add second token
            
            config.symbols[0] = "USDC";
            config.symbols[1] = "PYUSD";
            
            config.owner = 0xDb25832bA515FD47c6F673eBD98107cdD7632910;
            
        } else if (chainId == 421614) {
            // Arbitrum Sepolia
            config.tokens = new address[](2);
            config.symbols = new string[](2);
            
            config.tokens[0] = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d; // USDC Arbitrum Sepolia
            config.tokens[1] = 0x0000000000000000000000000000000000000000; // TODO: Add second token
            
            config.symbols[0] = "USDC";
            config.symbols[1] = "PYUSD";
            
            config.owner = 0xDb25832bA515FD47c6F673eBD98107cdD7632910;
            
        } else if (chainId == 11155420) {
            // Optimism Sepolia
            config.tokens = new address[](2);
            config.symbols = new string[](2);
            
            config.tokens[0] = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7; // USDC Optimism Sepolia
            config.tokens[1] = 0x0000000000000000000000000000000000000000; // TODO: Add second token
            
            config.symbols[0] = "USDC";
            config.symbols[1] = "PYUSD";
            
            config.owner = 0xDb25832bA515FD47c6F673eBD98107cdD7632910;
            
        } else if (chainId == 545) {
            // Flow EVM Testnet
            config.tokens = new address[](2);
            config.symbols = new string[](2);
            
            config.tokens[0] = 0xE103Bb1b2E2dd1c5eD7b9B2D84f78Eb4B004cF7a; // Token 1
            config.tokens[1] = 0x9857E9b660221cED694dEAC6679Cdb0bEAedFF6F; // Token 2
            
            config.symbols[0] = "USDC";
            config.symbols[1] = "PYUSD";
            
            config.owner = 0xDb25832bA515FD47c6F673eBD98107cdD7632910;
            
        } else if (chainId == 84532) {
            // Base Sepolia
            config.tokens = new address[](2);
            config.symbols = new string[](2);
            
            config.tokens[0] = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // USDC Base Sepolia
            config.tokens[1] = 0x0000000000000000000000000000000000000000; // TODO: Add second token
            
            config.symbols[0] = "USDC";
            config.symbols[1] = "PYUSD";
            
            config.owner = 0xDb25832bA515FD47c6F673eBD98107cdD7632910;
            
        } else {
            revert("ChainConfig: Unsupported chain ID");
        }

        return config;
    }

    function getChainName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 11155111) return "Sepolia";
        if (chainId == 80001) return "Mumbai";
        if (chainId == 421614) return "Arbitrum Sepolia";
        if (chainId == 11155420) return "Optimism Sepolia";
        if (chainId == 545) return "Flow EVM Testnet";
        if (chainId == 84532) return "Base Sepolia";
        return "Unknown Chain";
    }
}