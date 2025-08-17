// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CrossChainSwap.sol";

contract DeployDestination is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DestinationChainReceiver dest = new DestinationChainReceiver(
            0x68ecD5616Af65B1354541f94c8546502Db843233,
            0x036CbD53842c5426634e7929541eC2318f3dCF7e, // USDC Base Sepolia
            0x20180e82dB7Ac476A9F3b0aF245338288c88D0Ef // Actual PUSD
        );
        console.log("Destination deployed at:", address(dest));

        vm.stopBroadcast();
    }
}

// forge script script/DeployDestination.s.sol:DeployDestination --rpc-url base_sepolia --broadcast
//   Destination deployed at: 0xc002509A8A93Ee6809d00F3072414a1fA1cDDd22
