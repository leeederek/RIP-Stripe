// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/OrbitalPool.sol";
import "../src/libraries/OrbitalTypes.sol";
import "./mocks/MockERC20.sol";

contract OrbitalPoolBasicTest is Test {
    OrbitalPool public pool;
    MockERC20[] public tokens;
    
    address public owner = address(0x1);
    address public lp1 = address(0x2);
    address public lp2 = address(0x3);
    address public lp3 = address(0x4);
    address public trader = address(0x5);
    
    uint256 constant PRECISION = 1e18;
    
    function setUp() public {
        vm.startPrank(owner);
    }
    
    function test_PoolCreation() public {
        // Create 3-token pool
        address[] memory tokenAddresses = new address[](3);
        string[] memory symbols = new string[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            MockERC20 token = new MockERC20(
                string(abi.encodePacked("Token ", vm.toString(i))),
                string(abi.encodePacked("TKN", vm.toString(i))),
                18
            );
            tokens.push(token);
            tokenAddresses[i] = address(token);
            symbols[i] = string(abi.encodePacked("TKN", vm.toString(i)));
        }
        
        pool = new OrbitalPool(tokenAddresses, symbols, owner);
        vm.stopPrank();
        
        // Verify pool setup
        assertEq(pool.tokenCount(), 3);
        assertEq(pool.tokens(0), tokenAddresses[0]);
        assertEq(pool.tokens(1), tokenAddresses[1]);
        assertEq(pool.tokens(2), tokenAddresses[2]);
        
        // Check initial state
        OrbitalTypes.PoolStats memory stats = pool.getPoolStats();
        assertEq(stats.totalTicks, 0);
        assertEq(stats.totalLiquidity, 0);
    }
    
    function test_StablecoinPool() public {
        // Create 4 stablecoin tokens with different decimals
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6);
        MockERC20 usdt = new MockERC20("Tether", "USDT", 6);
        MockERC20 pyusd = new MockERC20("PayPal USD", "PYUSD", 6);
        MockERC20 dai = new MockERC20("Dai Stablecoin", "DAI", 18);
        
        address[] memory stableAddresses = new address[](4);
        stableAddresses[0] = address(usdc);
        stableAddresses[1] = address(usdt);
        stableAddresses[2] = address(pyusd);
        stableAddresses[3] = address(dai);
        
        string[] memory stableSymbols = new string[](4);
        stableSymbols[0] = "USDC";
        stableSymbols[1] = "USDT";
        stableSymbols[2] = "PYUSD";
        stableSymbols[3] = "DAI";
        
        // Create pool
        pool = new OrbitalPool(stableAddresses, stableSymbols, owner);
        vm.stopPrank();
        
        // Verify stablecoin pool setup
        assertEq(pool.tokenCount(), 4);
        
        // Test that tokens have correct addresses
        assertEq(pool.tokens(0), address(usdc));
        assertEq(pool.tokens(1), address(usdt));
        assertEq(pool.tokens(2), address(pyusd));
        assertEq(pool.tokens(3), address(dai));
        
        // Verify token decimals are preserved in the tokens themselves
        assertEq(usdc.decimals(), 6);
        assertEq(usdt.decimals(), 6);
        assertEq(pyusd.decimals(), 6);
        assertEq(dai.decimals(), 18);
    }
    
    function test_LargeTokenPool() public {
        // Create 10-token pool
        address[] memory tokenAddresses = new address[](10);
        string[] memory symbols = new string[](10);
        
        for (uint256 i = 0; i < 10; i++) {
            MockERC20 token = new MockERC20(
                string(abi.encodePacked("Token ", vm.toString(i))),
                string(abi.encodePacked("T", vm.toString(i))),
                18
            );
            tokens.push(token);
            tokenAddresses[i] = address(token);
            symbols[i] = string(abi.encodePacked("T", vm.toString(i)));
        }
        
        pool = new OrbitalPool(tokenAddresses, symbols, owner);
        vm.stopPrank();
        
        // Verify 10-token pool
        assertEq(pool.tokenCount(), 10);
        
        // Check all tokens are properly registered
        for (uint256 i = 0; i < 10; i++) {
            assertEq(pool.tokens(i), tokenAddresses[i]);
        }
        
        // Pool should start empty
        OrbitalTypes.PoolStats memory stats = pool.getPoolStats();
        assertEq(stats.totalTicks, 0);
        assertEq(stats.interiorTicks, 0);
        assertEq(stats.boundaryTicks, 0);
        assertEq(stats.totalLiquidity, 0);
        
        // Verify token symbols
        string[] memory poolSymbols = stats.tokenSymbols;
        for (uint256 i = 0; i < 10; i++) {
            assertEq(poolSymbols[i], symbols[i]);
        }
    }
    
    function test_TokenMinting() public {
        // Create simple 2-token pool for testing token operations
        MockERC20 token0 = new MockERC20("Token 0", "TKN0", 18);
        MockERC20 token1 = new MockERC20("Token 1", "TKN1", 18);
        
        // Test minting
        token0.mint(lp1, 1000 * 1e18);
        token1.mint(lp1, 1000 * 1e18);
        
        assertEq(token0.balanceOf(lp1), 1000 * 1e18);
        assertEq(token1.balanceOf(lp1), 1000 * 1e18);
        
        // Test token transfers
        vm.startPrank(lp1);
        token0.transfer(lp2, 100 * 1e18);
        assertEq(token0.balanceOf(lp1), 900 * 1e18);
        assertEq(token0.balanceOf(lp2), 100 * 1e18);
        vm.stopPrank();
    }
    
    function test_QuoteFunction() public {
        // Create pool
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
        
        // Test quote function (should return 0 for empty pool)
        uint256 quote = pool.getQuote(0, 1, 100 * 1e18);
        assertEq(quote, 0); // Empty pool returns 0
    }
}