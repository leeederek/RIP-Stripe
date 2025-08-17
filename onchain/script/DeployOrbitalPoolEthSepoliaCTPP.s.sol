// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/OrbitalPool.sol";

contract DeployOrbitalPoolCTPP is Script {
    // Sphere Swap deployed stablecoins on Ethereum Sepolia
    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;  
    address constant PYUSD = 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9; 

    
    // Owner address (your wallet)
    address constant OWNER = 0xf59dA181591dbB122A894372C6E44cC079A7Bb3F;

    function run() external {
        vm.startBroadcast();

        // Prepare token arrays
        address[] memory tokens = new address[](4);
        tokens[0] = USDC;
        tokens[1] = PYUSD;

        string[] memory symbols = new string[](4);
        symbols[0] = "USDC";
        symbols[1] = "PYUSD";

        // Deploy OrbitalPool
        OrbitalPool pool = new OrbitalPool(
            tokens
        );

        console.log("OrbitalPool deployed at:", address(pool));
        vm.stopBroadcast();
    }
}



