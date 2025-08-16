// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/OrbitalPool.sol";
import "./ChainConfig.sol";

contract DeployOrbitalPoolMultiChain is Script {
    // Events for logging deployments
    event PoolDeployed(uint256 chainId, address pool, address[] tokens, address owner);

    // Store deployments for verification
    mapping(uint256 => address) public deployments;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying from address:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Chain Name:", ChainConfig.getChainName(block.chainid));
        
        // Get chain-specific configuration
        ChainConfig.TokenConfig memory config = ChainConfig.getConfig(block.chainid);
        
        // Validate configuration
        require(config.tokens.length > 0, "No tokens configured for this chain");
        require(config.tokens.length == config.symbols.length, "Token/symbol mismatch");
        require(config.owner != address(0), "Owner not set for this chain");
        
        console.log("Deploying OrbitalPool with:");
        console.log("  Owner:", config.owner);
        console.log("  Number of tokens:", config.tokens.length);
        
        for (uint i = 0; i < config.tokens.length; i++) {
            console.log("  Token", i, ":", config.tokens[i], "-", config.symbols[i]);
        }
        
        // Start broadcast
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy with CREATE2 for deterministic addresses across chains
        bytes32 salt = keccak256(abi.encodePacked("OrbitalPool-v1", block.chainid));
        
        OrbitalPool pool = new OrbitalPool{salt: salt}(
            config.tokens,
            config.symbols,
            config.owner
        );
        
        vm.stopBroadcast();
        
        // Log deployment
        console.log("OrbitalPool deployed at:", address(pool));
        deployments[block.chainid] = address(pool);
        
        // Emit event for off-chain tracking
        emit PoolDeployed(block.chainid, address(pool), config.tokens, config.owner);
        
        // Write deployment info to file
        string memory deploymentInfo = string(
            abi.encodePacked(
                '{"chain":"',
                ChainConfig.getChainName(block.chainid),
                '","chainId":',
                vm.toString(block.chainid),
                ',"pool":"',
                vm.toString(address(pool)),
                '","owner":"',
                vm.toString(config.owner),
                '","timestamp":',
                vm.toString(block.timestamp),
                '}'
            )
        );
        
        string memory filename = string(
            abi.encodePacked(
                "./deployments/",
                vm.toString(block.chainid),
                "-",
                vm.toString(address(pool)),
                ".json"
            )
        );
        
        vm.writeFile(filename, deploymentInfo);
        console.log("Deployment info written to:", filename);
    }
    
    // Helper function to verify deployment on a specific chain
    function verify() external view {
        address deployed = deployments[block.chainid];
        if (deployed != address(0)) {
            console.log("OrbitalPool is deployed at:", deployed, "on chain", block.chainid);
            
            // Verify contract code
            OrbitalPool pool = OrbitalPool(deployed);
            console.log("Pool owner:", pool.owner());
            console.log("Number of tokens:", pool.getN());
        } else {
            console.log("No deployment found for chain", block.chainid);
        }
    }
}