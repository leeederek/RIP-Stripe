// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/OrbitalPool.sol";

contract DeployOrbitalPoolEthSepolia is Script {
    // Sphere Swap deployed stablecoins on Ethereum Sepolia
    address constant USDC = 0xa1DBc4F41540a2aA338e9aD2F5058deF509E1b95; 

    address constant USDT = 0xC01def8bD0C4C9790199ABa304C944Be9491FCc3;  
    address constant PYUSD = 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9; 
    address constant USDE = 0xb483e7D477c7cea5e906584568198E057cb209bB; // Sphere Swap USDe
    
    // Owner address (your wallet)
    address constant OWNER = 0xf59dA181591dbB122A894372C6E44cC079A7Bb3F;

    function run() external {
        vm.startBroadcast();

        // Prepare token arrays
        address[] memory tokens = new address[](4);
        tokens[0] = USDC;
        tokens[1] = USDT;
        tokens[2] = PYUSD;
        tokens[3] = USDE;

        string[] memory symbols = new string[](4);
        symbols[0] = "USDC";
        symbols[1] = "USDT";
        symbols[2] = "PYUSD";
        symbols[3] = "USDe";

        // Deploy OrbitalPool
        OrbitalPool pool = new OrbitalPool(
            tokens
        );

        console.log("OrbitalPool deployed at:", address(pool));
        console.log("Network: Ethereum Sepolia");
        console.log("Owner:", OWNER);
        console.log("Tokens:");
        console.log("  USDC:", USDC);
        console.log("  USDT:", USDT);
        console.log("  PYUSD:", PYUSD);
        console.log("  USDe:", USDE);

        vm.stopBroadcast();
    }
}

