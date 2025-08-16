// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/OrbitalPool.sol";
import "../src/libraries/OrbitalTypes.sol";
import "./mocks/MockERC20.sol";

contract OrbitalPoolSimpleTest is Test {
    OrbitalPool public pool;
    MockERC20[] public tokens;
    
    address public owner = address(0x1);
    address public lp1 = address(0x2);
    
    uint256 constant PRECISION = 1e18;
    
    function setUp() public {
        vm.startPrank(owner);
    }
    
    function test_SimpleLiquidity() public {
        // Create 2-token pool for simplicity
        address[] memory tokenAddresses = new address[](2);
        string[] memory symbols = new string[](2);
        
        MockERC20 token0 = new MockERC20("Token 0", "TKN0", 18);
        MockERC20 token1 = new MockERC20("Token 1", "TKN1", 18);
        
        tokenAddresses[0] = address(token0);
        tokenAddresses[1] = address(token1);
        symbols[0] = "TKN0";
        symbols[1] = "TKN1";
        
        pool = new OrbitalPool(tokenAddresses, symbols, owner);
        vm.stopPrank();
        
        // Mint and approve
        vm.startPrank(lp1);
        token0.mint(lp1, 100000 * 1e18);
        token1.mint(lp1, 100000 * 1e18);
        
        token0.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);
        
        // Add liquidity
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000 * 1e18;
        amounts[1] = 1000 * 1e18;
        
        console.log("Adding liquidity with amounts:", amounts[0], amounts[1]);
        
        OrbitalTypes.LiquidityResult memory result = pool.addLiquidity(
            amounts,
            0,
            99 * 1e16, // 0.99 = 99%
            30 // 0.3% fee
        );
        
        assertEq(result.success, true);
        console.log("Liquidity added successfully, tickId:", result.tickId);
        
        vm.stopPrank();
    }
}