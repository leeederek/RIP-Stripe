// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/OrbitalPool.sol";

contract DeployOrbitalPool is Script {
    // Token addresses from DeployStablecoins deployment on Arbitrum Sepolia
    address constant USDC = 0x7197cba866D739d20228321467F6BBC6cA676A09;
    address constant USDT = 0x1f71B914e2A92052f7e0A5B1dB7f8b8fe209D5F3;
    address constant PYUSD = 0xF0B61d1c7ed86a1d1b2E1Cf7a19f0AF0F783b3F3;
    address constant USDe = 0x8786aB4F9559D7A86890a3a3d9e4d0841C42EbCD;
    
    // Owner address
    address constant OWNER = 0xf59dA181591dbB122A894372C6E44cC079A7Bb3F;

    function run() external {
        vm.startBroadcast();

        // Prepare token arrays
        address[] memory tokens = new address[](4);
        tokens[0] = USDC;
        tokens[1] = USDT;
        tokens[2] = PYUSD;
        tokens[3] = USDe;

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
        console.log("Owner:", OWNER);
        console.log("Tokens:");
        console.log("  USDC:", USDC);
        console.log("  USDT:", USDT);
        console.log("  PYUSD:", PYUSD);
        console.log("  USDe:", USDe);

        vm.stopBroadcast();
    }
}