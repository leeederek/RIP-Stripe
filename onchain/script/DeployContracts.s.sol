// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CrossChainSwap.sol";

contract DeploySourceSepolia is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);

        SourceChainSwapAndBridge source = new SourceChainSwapAndBridge(
            0xBAB68589Ca860B06F839D7Ab41F7d81A7ae5f470, // OrbitalPoolSepolia
            0xa1DBc4F41540a2aA338e9aD2F5058deF509E1b95, // USDC Sepolia
            0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9, // pusdSepolia
            0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA // cctpMessengerSepolia (token messenger address from Circle)
        );
        console.log("SourceChainSwapAndBridge deployed at:", address(source));

        vm.stopBroadcast();
    }
}

contract DeployDestinationBaseSepolia is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(key);

        DestinationChainReceiver dest = new DestinationChainReceiver(
            /* orbitalPoolBaseSepolia (if exists) or zero */,
            0x036CbD53842c5426634e7929541eC2318f3dCF7e, // USDC Base Sepolia
            /* pusdBaseSepolia (optional) */
        );
        console.log("DestinationChainReceiver deployed at:", address(dest));

        vm.stopBroadcast();
    }
}
