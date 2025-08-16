// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/OrbitalPool.sol";
import "../src/libraries/OrbitalTypes.sol";
import "./mocks/MockERC20.sol";

contract OrbitalPoolTest is Test {
    OrbitalPool public pool;
    MockERC20[] public tokens;
    
    address public owner = address(0x1);
    address public lp1 = address(0x2);
    address public lp2 = address(0x3);
    address public lp3 = address(0x4);
    address public trader = address(0x5);
    
    uint256 constant PRECISION = 1e18;
    uint256 constant INITIAL_BALANCE = 1000000 * 1e18;
    
    
    function setUp() public {
        vm.startPrank(owner);
    }
    
    function createTokens(uint256 count) internal returns (address[] memory tokenAddresses, string[] memory symbols) {
        tokenAddresses = new address[](count);
        symbols = new string[](count);
        
        for (uint256 i = 0; i < count; i++) {
            string memory symbol = string(abi.encodePacked("TKN", vm.toString(i)));
            MockERC20 token = new MockERC20(
                string(abi.encodePacked("Token ", vm.toString(i))),
                symbol,
                18
            );
            tokens.push(token);
            tokenAddresses[i] = address(token);
            symbols[i] = symbol;
            
            // Mint tokens to test addresses
            token.mint(lp1, INITIAL_BALANCE);
            token.mint(lp2, INITIAL_BALANCE);
            token.mint(lp3, INITIAL_BALANCE);
            token.mint(trader, INITIAL_BALANCE);
        }
    }
    
    function approveTokens(address user, address poolAddress, uint256 amount) internal {
        vm.startPrank(user);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].approve(poolAddress, amount);
        }
        vm.stopPrank();
    }
    
    function test_ThreeLiquidityProvidersFlow() public {
        // Create 4-token pool
        (address[] memory tokenAddresses, string[] memory symbols) = createTokens(4);
        pool = new OrbitalPool(tokenAddresses, symbols, owner);
        
        // Approve tokens for all users
        approveTokens(lp1, address(pool), type(uint256).max);
        approveTokens(lp2, address(pool), type(uint256).max);
        approveTokens(lp3, address(pool), type(uint256).max);
        approveTokens(trader, address(pool), type(uint256).max);
        
        // LP1 adds liquidity
        vm.startPrank(lp1);
        uint256[] memory amounts1 = new uint256[](4);
        amounts1[0] = 10000 * 1e18;
        amounts1[1] = 10000 * 1e18;
        amounts1[2] = 10000 * 1e18;
        amounts1[3] = 10000 * 1e18;
        
        OrbitalTypes.LiquidityResult memory result1 = pool.addLiquidity(
            amounts1,
            0,
            0.99 * 1e18, // 99% depeg tolerance
            30 // 0.3% fee
        );
        vm.stopPrank();
        
        assertEq(result1.success, true);
        uint256 tickId1 = result1.tickId;
        
        // LP2 adds liquidity
        vm.startPrank(lp2);
        uint256[] memory amounts2 = new uint256[](4);
        amounts2[0] = 5000 * 1e18;
        amounts2[1] = 5000 * 1e18;
        amounts2[2] = 5000 * 1e18;
        amounts2[3] = 5000 * 1e18;
        
        OrbitalTypes.LiquidityResult memory result2 = pool.addLiquidity(
            amounts2,
            0,
            0.98 * 1e18, // 98% depeg tolerance
            50 // 0.5% fee
        );
        vm.stopPrank();
        
        assertEq(result2.success, true);
        uint256 tickId2 = result2.tickId;
        
        // LP3 adds liquidity
        vm.startPrank(lp3);
        uint256[] memory amounts3 = new uint256[](4);
        amounts3[0] = 7500 * 1e18;
        amounts3[1] = 7500 * 1e18;
        amounts3[2] = 7500 * 1e18;
        amounts3[3] = 7500 * 1e18;
        
        OrbitalTypes.LiquidityResult memory result3 = pool.addLiquidity(
            amounts3,
            0,
            0.995 * 1e18, // 99.5% depeg tolerance
            20 // 0.2% fee
        );
        vm.stopPrank();
        
        assertEq(result3.success, true);
        uint256 tickId3 = result3.tickId;
        
        // Execute some swaps
        vm.startPrank(trader);
        
        // Swap 1: Token0 -> Token1
        uint256 swapAmount1 = 100 * 1e18;
        uint256 balanceBefore1 = tokens[1].balanceOf(trader);
        
        OrbitalTypes.TradeResult memory trade1 = pool.swap(
            tokenAddresses[0],
            tokenAddresses[1],
            swapAmount1,
            0,
            block.timestamp + 3600
        );
        
        uint256 balanceAfter1 = tokens[1].balanceOf(trader);
        assertGt(balanceAfter1, balanceBefore1);
        
        // Swap 2: Token2 -> Token3
        uint256 swapAmount2 = 200 * 1e18;
        uint256 balanceBefore2 = tokens[3].balanceOf(trader);
        
        OrbitalTypes.TradeResult memory trade2 = pool.swap(
            tokenAddresses[2],
            tokenAddresses[3],
            swapAmount2,
            0,
            block.timestamp + 3600
        );
        
        uint256 balanceAfter2 = tokens[3].balanceOf(trader);
        assertGt(balanceAfter2, balanceBefore2);
        
        // Swap 3: Token1 -> Token0 (reverse)
        uint256 swapAmount3 = 150 * 1e18;
        pool.swap(
            tokenAddresses[1],
            tokenAddresses[0],
            swapAmount3,
            0,
            block.timestamp + 3600
        );
        
        vm.stopPrank();
        
        // LP1 removes liquidity
        vm.startPrank(lp1);
        uint256[] memory balancesBefore = new uint256[](4);
        for (uint256 i = 0; i < 4; i++) {
            balancesBefore[i] = tokens[i].balanceOf(lp1);
        }
        
        (uint256[] memory amounts, uint256[] memory fees) = pool.removeLiquidity(tickId1);
        
        // Check LP1 received tokens back plus fees
        for (uint256 i = 0; i < 4; i++) {
            uint256 balanceAfter = tokens[i].balanceOf(lp1);
            assertGt(balanceAfter, balancesBefore[i]);
            assertGt(amounts[i] + fees[i], 0);
        }
        vm.stopPrank();
        
        // LP3 removes liquidity
        vm.startPrank(lp3);
        pool.removeLiquidity(tickId3);
        vm.stopPrank();
        
        // Verify LP2's position still exists
        OrbitalTypes.PoolStats memory stats = pool.getPoolStats();
        assertEq(stats.totalTicks, 1); // Only LP2's tick remains
    }
    
    function test_FourTokenStablecoinPool() public {
        // Create 4 stablecoin tokens
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
        
        // Mint and approve tokens
        vm.startPrank(lp1);
        usdc.mint(lp1, 1000000 * 1e6); // 1M USDC
        usdt.mint(lp1, 1000000 * 1e6); // 1M USDT
        pyusd.mint(lp1, 1000000 * 1e6); // 1M PYUSD
        dai.mint(lp1, 1000000 * 1e18); // 1M DAI
        
        usdc.approve(address(pool), type(uint256).max);
        usdt.approve(address(pool), type(uint256).max);
        pyusd.approve(address(pool), type(uint256).max);
        dai.approve(address(pool), type(uint256).max);
        
        // Add liquidity with normalized amounts
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100000 * 1e6;  // 100k USDC
        amounts[1] = 100000 * 1e6;  // 100k USDT
        amounts[2] = 100000 * 1e6;  // 100k PYUSD
        amounts[3] = 100000 * 1e18; // 100k DAI
        
        OrbitalTypes.LiquidityResult memory result = pool.addLiquidity(
            amounts,
            0,
            0.995 * 1e18, // 99.5% depeg tolerance for stablecoins
            10 // 0.1% fee for stablecoin pool
        );
        
        assertEq(result.success, true);
        vm.stopPrank();
        
        // Test swaps between stablecoins
        vm.startPrank(trader);
        usdc.mint(trader, 10000 * 1e6);
        usdc.approve(address(pool), type(uint256).max);
        
        // Swap USDC to DAI using index-based swap
        uint256 daiBefore = dai.balanceOf(trader);
        
        uint256 amountOut = pool.swapExactIn(
            0, // USDC index
            3, // DAI index
            1000 * 1e6, // 1000 USDC
            0,
            trader
        );
        
        uint256 daiAfter = dai.balanceOf(trader);
        assertGt(daiAfter, daiBefore);
        
        // The output should be close to input considering decimal differences
        // 1000 USDC (6 decimals) should give approximately 1000 DAI (18 decimals)
        assertApproxEqRel(amountOut, 1000 * 1e18, 0.01 * 1e18); // 1% tolerance
        
        vm.stopPrank();
    }
    
    function test_TenTokenPoolLowSlippage() public {
        // Create 10-token pool
        (address[] memory tokenAddresses, string[] memory symbols) = createTokens(10);
        pool = new OrbitalPool(tokenAddresses, symbols, owner);
        
        // Large liquidity provider adds significant liquidity
        vm.startPrank(lp1);
        for (uint256 i = 0; i < 10; i++) {
            tokens[i].approve(address(pool), type(uint256).max);
        }
        
        uint256[] memory largeAmounts = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            largeAmounts[i] = 100000 * 1e18; // 100k tokens each
        }
        
        OrbitalTypes.LiquidityResult memory result = pool.addLiquidity(
            largeAmounts,
            0,
            0.99 * 1e18, // 99% depeg tolerance
            30 // 0.3% fee
        );
        
        assertEq(result.success, true);
        vm.stopPrank();
        
        // Execute multiple swaps and measure slippage
        vm.startPrank(trader);
        for (uint256 i = 0; i < 10; i++) {
            tokens[i].approve(address(pool), type(uint256).max);
        }
        
        // Test 1: Small swap (0.1% of pool)
        uint256 smallSwap = 100 * 1e18;
        uint256 quote1 = pool.getQuote(0, 1, smallSwap);
        
        OrbitalTypes.TradeResult memory trade1 = pool.swap(
            tokenAddresses[0],
            tokenAddresses[1],
            smallSwap,
            0,
            block.timestamp + 3600
        );
        
        // For small swaps, output should be very close to input
        uint256 slippage1 = ((smallSwap - trade1.outputAmount) * 1e18) / smallSwap;
        assertLt(slippage1, 0.005 * 1e18); // Less than 0.5% slippage
        
        // Test 2: Medium swap (1% of pool)
        uint256 mediumSwap = 1000 * 1e18;
        OrbitalTypes.TradeResult memory trade2 = pool.swap(
            tokenAddresses[2],
            tokenAddresses[3],
            mediumSwap,
            0,
            block.timestamp + 3600
        );
        
        uint256 slippage2 = ((mediumSwap - trade2.outputAmount) * 1e18) / mediumSwap;
        assertLt(slippage2, 0.02 * 1e18); // Less than 2% slippage
        
        // Test 3: Sequential swaps through multiple tokens
        uint256 amount = 500 * 1e18;
        uint256[] memory balances = new uint256[](5);
        
        // Record initial balance
        balances[0] = tokens[0].balanceOf(trader);
        
        // Swap chain: Token0 -> Token1 -> Token2 -> Token3 -> Token4
        for (uint256 i = 0; i < 4; i++) {
            pool.swap(
                tokenAddresses[i],
                tokenAddresses[i + 1],
                amount,
                0,
                block.timestamp + 3600
            );
            
            // Use output as input for next swap
            amount = tokens[i + 1].balanceOf(trader) - balances[i + 1];
            balances[i + 1] = tokens[i + 1].balanceOf(trader);
        }
        
        // Final amount should still be close to initial due to low slippage
        uint256 finalAmount = tokens[4].balanceOf(trader) - balances[4];
        uint256 totalSlippage = ((500 * 1e18 - finalAmount) * 1e18) / (500 * 1e18);
        
        // Even after 4 swaps, total slippage should be reasonable
        assertLt(totalSlippage, 0.05 * 1e18); // Less than 5% total slippage
        
        vm.stopPrank();
        
        // Verify pool maintains balance
        OrbitalTypes.PoolStats memory stats = pool.getPoolStats();
        assertEq(stats.totalTicks, 1);
        assertGt(stats.totalLiquidity, 0);
    }
    
    function test_SwapExactInWithRecipient() public {
        // Create 3-token pool
        (address[] memory tokenAddresses, string[] memory symbols) = createTokens(3);
        pool = new OrbitalPool(tokenAddresses, symbols, owner);
        
        // Add liquidity
        vm.startPrank(lp1);
        for (uint256 i = 0; i < 3; i++) {
            tokens[i].approve(address(pool), type(uint256).max);
        }
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10000 * 1e18;
        amounts[1] = 10000 * 1e18;
        amounts[2] = 10000 * 1e18;
        
        pool.addLiquidity(amounts, 0, 0.99 * 1e18, 30);
        vm.stopPrank();
        
        // Test swapExactIn with different recipient
        address recipient = address(0x999);
        vm.startPrank(trader);
        tokens[0].approve(address(pool), type(uint256).max);
        
        uint256 recipientBefore = tokens[1].balanceOf(recipient);
        uint256 traderBefore = tokens[1].balanceOf(trader);
        
        uint256 amountOut = pool.swapExactIn(
            0, // token 0
            1, // token 1
            100 * 1e18,
            0,
            recipient
        );
        
        // Verify recipient received tokens, not trader
        assertEq(tokens[1].balanceOf(recipient), recipientBefore + amountOut);
        assertEq(tokens[1].balanceOf(trader), traderBefore);
        
        vm.stopPrank();
    }
}