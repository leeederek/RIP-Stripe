// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CrossChainSwap.sol";

contract DeployCrossChainSwap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy on Ethereum Sepolia
        SourceChainSwapAndBridge source = new SourceChainSwapAndBridge(
            0xBAB68589Ca860B06F839D7Ab41F7d81A7ae5f470,
            0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, // USDC Base Sepolia 
            0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9, // Actual PUSD
            0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA//CCTPMessengerAddressSepolia
        );
        console.log("Source deployed at:", address(source));

        vm.stopBroadcast();
    }
}


// forge script script/DeployCrossChainSwap.s.sol:DeployCrossChainSwap \
//   --rpc-url ethereum_sepolia \
//   --broadcast
// // //   Destination deployed at: 0xC72C9c9aFBA843Aad6f021c80F190ce54990C760