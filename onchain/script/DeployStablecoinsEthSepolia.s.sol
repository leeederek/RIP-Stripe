// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployStablecoinsEthSepolia is Script {
    // Predefined addresses for ETH Sepolia
    address constant OWNER  = 0xf59dA181591dbB122A894372C6E44cC079A7Bb3F;
    address constant USER_1 = 0x3173Ed1Ec423f5071045D861CaB532C2909fB4c0;
    address constant USER_2 = 0xE265064afDbC57e008d0fb2A481826aDD6f44447;

    function run() external {
        vm.startBroadcast();

        console.log("=== Deploying Stablecoins on Ethereum Sepolia ===");
        console.log("Deployer:", msg.sender);
        console.log("Network: Ethereum Sepolia (Chain ID: 11155111)");
        console.log("");

        // Deploy mock stablecoins with correct decimals
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6, 1_000_000 * 10**6);
        MockERC20 usdt = new MockERC20("Tether USD", "USDT", 6, 1_000_000 * 10**6);
        // MockERC20 pyusd = new MockERC20("PayPal USD", "PYUSD", 6, 1_000_000 * 10**6);
        IERC20 pyusd = IERC20(0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9);
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
        console.log("USDC minted: 100,000 to each user");

        // USDT distribution
        usdt.mint(OWNER, mintAmount6d);
        usdt.mint(USER_1, mintAmount6d);
        usdt.mint(USER_2, mintAmount6d);        
        console.log("USDT minted: 100,000 to each user");

        // PYUSD distribution - Note: PYUSD is a real contract, cannot mint
        console.log("PYUSD: Real contract, skipping minting");

        // USDe distribution 
        usde.mint(OWNER,  mintAmount6d);
        usde.mint(USER_1, mintAmount6d);
        usde.mint(USER_2, mintAmount6d);
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
// https://sepolia.etherscan.io/address/0xBAB68589Ca860B06F839D7Ab41F7d81A7ae5f470
//   USDC: 0xa1DBc4F41540a2aA338e9aD2F5058deF509E1b95
//   USDT: 0xC01def8bD0C4C9790199ABa304C944Be9491FCc3
//   PYUSD: 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9
//   USDe: 0xb483e7D477c7cea5e906584568198E057cb209bB
  
//   Recipients:
//   OWNER: 0xf59dA181591dbB122A894372C6E44cC079A7Bb3F
//   USER_1: 0x3173Ed1Ec423f5071045D861CaB532C2909fB4c0
//   USER_2: 0xE265064afDbC57e008d0fb2A481826aDD6f44447
  

