// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/OrbitalPool.sol";

contract DeployOrbitalPoolBaseSepolia is Script {
    // Sphere Swap deployed stablecoins on Base Sepolia

    address constant USDC = 0x50766571B3769d9CfC170f3b17668F3673F80EbA;
    address constant USDT = 0x3b7e3a661cec642fa7bCE0130e327b11FF0af43e;
    address constant PYUSD = 0x20180e82dB7Ac476A9F3b0aF245338288c88D0Ef;
    address constant USDE = 0x3f06895671C3a55cB84e1Cc221a9917755a985D6;
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
        console.log("Network: Base Sepolia");
        console.log("Owner:", OWNER);
        console.log("Tokens:");
        console.log("  USDC:", USDC);
        console.log("  USDT:", USDT);
        console.log("  PYUSD:", PYUSD);
        console.log("  USDe:", USDE);

        vm.stopBroadcast();
    }
}



//0x68ecD5616Af65B1354541f94c8546502Db843233