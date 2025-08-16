// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {OrbitalPool} from "../src/OrbitalPool.sol";

contract DeployOrbitalPool is Script {
    function run() external {
        // These are your constructor arguments
        address[] memory poolAddresses = new address[](2);
        poolAddresses[0] = 0xE103Bb1b2E2dd1c5eD7b9B2D84f78Eb4B004cF7a;
        poolAddresses[1] = 0x9857E9b660221cED694dEAC6679Cdb0bEAedFF6F;

        string[] memory poolNames = new string[](2);
        poolNames[0] = "USDC";
        poolNames[1] = "PYUSD";

        address poolController = 0xDb25832bA515FD47c6F673eBD98107cdD7632910;

        vm.startBroadcast();

        OrbitalPool newPool = new OrbitalPool(
            poolAddresses,
            poolNames,
            poolController
        );

        vm.stopBroadcast();
    }
}