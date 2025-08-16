// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockStablecoinFactory.sol";

contract DeployAndDistribute is Script {
    // Provided by you
    address constant OWNER  = 0xf59dA181591dbB122A894372C6E44cC079A7Bb3F;
    address constant USER_1 = 0x3173Ed1Ec423f5071045D861CaB532C2909fB4c0;
    address constant USER_2 = 0x806B7DE4adD0A154262Bae6A2ed08Ab4DEd757af;

    // Starter balances (adjust anytime)
    // 6-dec tokens use 1e6; 18-dec uses 1e18
    uint256 constant START_6  = 100_000 * 1e6;   // 100k units for USDC/USDT0/PYUSD
    uint256 constant START_18 = 100_000 * 1e18;  // 100k units for USDe

    function run() external {
        // Use PRIVATE_KEY from env for the deployer/broadcaster
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        // Deploy factory, setting OWNER as the owner of all tokens
        MockStablecoinFactory factory = new MockStablecoinFactory(OWNER);

        // Fetch token refs
        MockToken usdc  = factory.USDC();
        MockToken usdt0 = factory.USDT0();
        MockToken pyusd = factory.PYUSD();
        MockToken usde  = factory.USDe();

        // Mint & distribute from OWNER (token owner) to OWNER/USER_1/USER_2
        // Since msg.sender is the broadcaster, we need to transfer ownership to the broadcaster
        // OR we just call as OWNER via "prank". We'll transfer ownership to broadcaster for simplicity:
        usdc.transferOwnership(msg.sender);
        usdt0.transferOwnership(msg.sender);
        pyusd.transferOwnership(msg.sender);
        usde.transferOwnership(msg.sender);

        // Mint to three wallets
        _mintAll(usdc, START_6);
        _mintAll(usdt0, START_6);
        _mintAll(pyusd, START_6);
        _mintAll(usde, START_18);

        // Return ownership back to OWNER for cleanliness
        usdc.transferOwnership(OWNER);
        usdt0.transferOwnership(OWNER);
        pyusd.transferOwnership(OWNER);
        usde.transferOwnership(OWNER);

        vm.stopBroadcast();

        // Log addresses for convenience
        console2.log("Factory:    ", address(factory));
        console2.log("USDC:       ", address(usdc));
        console2.log("USDT0:      ", address(usdt0));
        console2.log("PYUSD:      ", address(pyusd));
        console2.log("USDe:       ", address(usde));
    }

    function _mintAll(MockToken t, uint256 amount) internal {
        t.mint(OWNER, amount);
        t.mint(USER_1, amount);
        t.mint(USER_2, amount);
    }
}
