// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MockERC20.sol";

contract DeployStablecoinsBaseSepolia is Script {
    // Predefined addresses for ETH Sepolia
    address constant OWNER  = 0xf59dA181591dbB122A894372C6E44cC079A7Bb3F;
    address constant USER_1 = 0x3173Ed1Ec423f5071045D861CaB532C2909fB4c0;
    address constant USER_2 = 0xE265064afDbC57e008d0fb2A481826aDD6f44447;
    address constant DAN = 0x1FF47D121E5971E012C0b2E2E088606a77Aa9377;
    function run() external {
        vm.startBroadcast();

        console.log("=== Deploying Stablecoins on Base Sepolia ===");
        console.log("Deployer:", msg.sender);
        console.log("Network: Base Sepolia ");
        console.log("");

        // Deploy mock stablecoins with correct decimals
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6, 1_000_000 * 10**6);
        MockERC20 usdt = new MockERC20("Tether USD", "USDT", 6, 1_000_000 * 10**6);
        MockERC20 pyusd = new MockERC20("PayPal USD", "PYUSD", 6, 1_000_000 * 10**6);
        MockERC20 usde = new MockERC20("Ethena USD", "USDe", 6, 1_000_000 * 10**6);

        console.log("Stablecoins deployed:");
        console.log("USDC:", address(usdc));
        console.log("USDT:", address(usdt));
        console.log("PYUSD:", address(pyusd));
        console.log("USDe:", address(usde));
        console.log("");

        // Mint tokens to predefined addresses
        uint256 mintAmount6d = 100_000 * 10**6; // For USDC, USDT, PYUSD (6 decimals)
        uint256 mintAmount18d = 100_000 ether;  // For USDe (18 decimals)

        console.log("Minting tokens to users...");
        
        // USDC distribution
        usdc.mint(OWNER, mintAmount6d);
        usdc.mint(USER_1, mintAmount6d);
        usdc.mint(USER_2, mintAmount6d);
        usdc.mint(DAN, mintAmount6d);
        console.log("USDC minted: 100,000 to each user");

        // USDT distribution
        usdt.mint(OWNER, mintAmount6d);
        usdt.mint(USER_1, mintAmount6d);
        usdt.mint(USER_2, mintAmount6d);
        usdt.mint(DAN, mintAmount6d);
        console.log("USDT minted: 100,000 to each user");

        // PYUSD distribution
        pyusd.mint(OWNER, mintAmount6d);
        pyusd.mint(USER_1, mintAmount6d);
        pyusd.mint(USER_2, mintAmount6d);
        pyusd.mint(DAN, mintAmount6d);
        console.log("PYUSD minted: 100,000 to each user");

        // USDe distribution (18 decimals)
        usde.mint(OWNER, mintAmount6d);
        usde.mint(USER_1, mintAmount6d);
        usde.mint(USER_2, mintAmount6d);
        usde.mint(DAN, mintAmount6d);
        console.log("USDe minted: 100,000 to each user");

        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Network: Ethereum Sepolia");
        console.log("USDC:", address(usdc));
        console.log("USDT:", address(usdt));
        console.log("PYUSD:", address(pyusd));
        console.log("USDe:", address(usde));
        console.log("");
        console.log("Recipients:");
        console.log("OWNER:", OWNER);
        console.log("USER_1:", USER_1);
        console.log("USER_2:", USER_2);
        console.log("");
        console.log("Stablecoin deployment complete!");

        vm.stopBroadcast();
    }
}

//   === Deployment Summary ===
//   Network: Ethereum Sepolia
//   USDC: 0x50766571B3769d9CfC170f3b17668F3673F80EbA
//   USDT: 0x3b7e3a661cec642fa7bCE0130e327b11FF0af43e
//   PYUSD: 0x20180e82dB7Ac476A9F3b0aF245338288c88D0Ef
//   USDe: 0x3f06895671C3a55cB84e1Cc221a9917755a985D6
  
//   Recipients:
//   OWNER: 0xf59dA181591dbB122A894372C6E44cC079A7Bb3F
//   USER_1: 0x3173Ed1Ec423f5071045D861CaB532C2909fB4c0
//   USER_2: 0xE265064afDbC57e008d0fb2A481826aDD6f44447

