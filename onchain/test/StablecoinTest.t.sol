// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MockERC20.sol";

contract StablecoinTest is Test {
    MockERC20 usdc;
    MockERC20 usde;

    address OWNER  = address(0xf59dA181591dbB122A894372C6E44cC079A7Bb3F);
    address USER_1 = address(0x3173Ed1Ec423f5071045D861CaB532C2909fB4c0);
    address USER_2 = address(0x806B7DE4adD0A154262Bae6A2ed08Ab4DEd757af);

    function setUp() public {
        usdc = new MockERC20("USD Coin", "USDC", 6, 1_000_000 * 10**6);
        usde = new MockERC20("Ethena USD", "USDe", 18, 1_000_000 ether);

        usdc.mint(OWNER, 100_000 * 10**6);
        usdc.mint(USER_1, 100_000 * 10**6);
        usdc.mint(USER_2, 100_000 * 10**6);

        usde.mint(OWNER, 100_000 ether);
        usde.mint(USER_1, 100_000 ether);
        usde.mint(USER_2, 100_000 ether);
    }

    function testBalances() public {
        assertEq(usdc.decimals(), 6);
        assertEq(usde.decimals(), 18);
        assertEq(usdc.balanceOf(OWNER), 100_000 * 10**6);
        assertEq(usde.balanceOf(USER_1), 100_000 ether);
    }
}
