// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/OrbitalPool.sol";
import "../src/MockERC20.sol";

contract OrbitalPoolTest is Test {
    OrbitalPool public pool;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockERC20 public tokenC;
    MockERC20 public tokenD;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);
    
    address[] public tokens;
    
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 1e6;
    uint256 public constant USER_BALANCE = 100_000 * 1e6;
    
    function setUp() public {
        // Deploy tokens
        tokenA = new MockERC20("Token A", "TKNA", 6, INITIAL_SUPPLY);
        tokenB = new MockERC20("Token B", "TKNB", 6, INITIAL_SUPPLY);
        tokenC = new MockERC20("Token C", "TKNC", 6, INITIAL_SUPPLY);
        tokenD = new MockERC20("Token D", "TKND", 6, INITIAL_SUPPLY);
        
        // Setup token array
        tokens.push(address(tokenA));
        tokens.push(address(tokenB));
        tokens.push(address(tokenC));
        tokens.push(address(tokenD));
        
        // Deploy pool
        vm.prank(owner);
        pool = new OrbitalPool(tokens);
        
        // Distribute tokens to users
        tokenA.transfer(user1, USER_BALANCE);
        tokenA.transfer(user2, USER_BALANCE);
        tokenA.transfer(user3, USER_BALANCE);
        
        tokenB.transfer(user1, USER_BALANCE);
        tokenB.transfer(user2, USER_BALANCE);
        tokenB.transfer(user3, USER_BALANCE);
        
        tokenC.transfer(user1, USER_BALANCE);
        tokenC.transfer(user2, USER_BALANCE);
        tokenC.transfer(user3, USER_BALANCE);
        
        tokenD.transfer(user1, USER_BALANCE);
        tokenD.transfer(user2, USER_BALANCE);
        tokenD.transfer(user3, USER_BALANCE);
    }
    
    function testPoolInitialization() public {
        assertEq(pool.tokenCount(), 4);
        assertEq(address(pool.tokens(0)), address(tokenA));
        assertEq(address(pool.tokens(1)), address(tokenB));
        assertEq(address(pool.tokens(2)), address(tokenC));
        assertEq(address(pool.tokens(3)), address(tokenD));
        assertEq(pool.owner(), owner);
    }
    
    function testAddLiquidity() public {
        vm.startPrank(user1);
        
        // Prepare amounts for liquidity
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1000 * 1e6; // tokenA
        amounts[1] = 1000 * 1e6; // tokenB
        amounts[2] = 1000 * 1e6; // tokenC
        amounts[3] = 1000 * 1e6; // tokenD
        
        // Approve tokens
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        // Add liquidity
        uint256 planeConstant = 1000 * 1e18; // Less than radius
        uint256 tickIndex = pool.addLiquidity(amounts, planeConstant);
        
        // Verify tick was created
        assertEq(tickIndex, 0);
        
        // Check tick info
        (
            uint256 radius,
            uint256 constant_,
            bool isInterior,
            address tickOwner,
            uint256[] memory reserves
        ) = pool.getTickInfo(tickIndex);
        
        assertGt(radius, 0);
        assertEq(constant_, planeConstant);
        assertTrue(isInterior);
        assertEq(tickOwner, user1);
        assertEq(reserves.length, 4);
        
        // Check user ticks
        uint256[] memory userTicks = pool.getUserTicks(user1);
        assertEq(userTicks.length, 1);
        assertEq(userTicks[0], tickIndex);
        
        vm.stopPrank();
    }
    
    function testAddLiquidityMultipleTicks() public {
        // User1 adds first liquidity
        vm.startPrank(user1);
        uint256[] memory amounts1 = new uint256[](4);
        amounts1[0] = 1000 * 1e6;
        amounts1[1] = 1000 * 1e6;
        amounts1[2] = 1000 * 1e6;
        amounts1[3] = 1000 * 1e6;
        
        tokenA.approve(address(pool), amounts1[0]);
        tokenB.approve(address(pool), amounts1[1]);
        tokenC.approve(address(pool), amounts1[2]);
        tokenD.approve(address(pool), amounts1[3]);
        
        uint256 tick1 = pool.addLiquidity(amounts1, 1000 * 1e6);
        vm.stopPrank();
        
        // User2 adds second liquidity
        vm.startPrank(user2);
        uint256[] memory amounts2 = new uint256[](4);
        amounts2[0] = 2000 * 1e6;
        amounts2[1] = 2000 * 1e6;
        amounts2[2] = 2000 * 1e6;
        amounts2[3] = 2000 * 1e6;
        
        tokenA.approve(address(pool), amounts2[0]);
        tokenB.approve(address(pool), amounts2[1]);
        tokenC.approve(address(pool), amounts2[2]);
        tokenD.approve(address(pool), amounts2[3]);
        
        uint256 tick2 = pool.addLiquidity(amounts2, 1500 * 1e18);
        vm.stopPrank();
        
        assertEq(tick1, 0);
        assertEq(tick2, 1);
        
        // Check reserves
        uint256[] memory totalReserves = pool.getReserves();
        assertGt(totalReserves[0], amounts1[0]);
        assertGt(totalReserves[1], amounts1[1]);
    }
    
    function testSwap() public {
        // First add liquidity
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 10000 * 1e6;
        amounts[1] = 10000 * 1e6;
        amounts[2] = 10000 * 1e6;
        amounts[3] = 10000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        pool.addLiquidity(amounts, 5000 * 1e6);
        vm.stopPrank();
        
        // User2 performs swap
        vm.startPrank(user2);
        uint256 swapAmount = 100 * 1e6;
        tokenA.approve(address(pool), swapAmount);
        
        uint256 balanceBeforeA = tokenA.balanceOf(user2);
        uint256 balanceBeforeB = tokenB.balanceOf(user2);
        
        // Swap tokenA for tokenB
        uint256 amountOut = pool.swap(0, 1, swapAmount, 1);
        
        uint256 balanceAfterA = tokenA.balanceOf(user2);
        uint256 balanceAfterB = tokenB.balanceOf(user2);
        
        // Verify swap occurred
        assertEq(balanceAfterA, balanceBeforeA - swapAmount);
        assertGt(balanceAfterB, balanceBeforeB);
        assertGt(amountOut, 0);
        
        vm.stopPrank();
    }
    
    function testGetAmountOut() public {
        console.log("=== Starting testGetAmountOut ===");
        
        // Add liquidity first
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 10000 * 1e6;
        amounts[1] = 10000 * 1e6;
        amounts[2] = 10000 * 1e6;
        amounts[3] = 10000 * 1e6;
        
        console.log("Adding liquidity:");
        console.log("  Token A amount:", amounts[0]);
        console.log("  Token B amount:", amounts[1]);
        console.log("  Token C amount:", amounts[2]);
        console.log("  Token D amount:", amounts[3]);
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        uint256 tickIndex = pool.addLiquidity(amounts, 5000 * 1e6);
        console.log("Liquidity added at tick index:", tickIndex);
        
        // Check reserves after adding liquidity
        uint256[] memory reserves = pool.getReserves();
        console.log("Pool reserves after liquidity:");
        console.log("  Reserve A:", reserves[0]);
        console.log("  Reserve B:", reserves[1]);
        console.log("  Reserve C:", reserves[2]);
        console.log("  Reserve D:", reserves[3]);
        
        vm.stopPrank();
        
        // Test quote functionality
        uint256 swapAmount = 100 * 1e6;
        console.log("\nTesting getAmountOut:");
        console.log("  Token In Index: 0 (Token A)");
        console.log("  Token Out Index: 1 (Token B)");
        console.log("  Swap Amount:", swapAmount);
        
        try pool.getAmountOut(0, 1, swapAmount) returns (uint256 expectedOut) {
            console.log("  Expected output amount:", expectedOut);
            console.log("  Swap fee:", pool.swapFee(), "basis points");
            
            if (expectedOut == 0) {
                console.log("ERROR: Expected output is zero!");
            }
            
            if (expectedOut >= swapAmount) {
                console.log("ERROR: Expected output is greater than or equal to input!");
                console.log("  This suggests fee calculation or swap math issue");
            }
            
            assertGt(expectedOut, 0, "Expected output should be greater than zero");
            assertLt(expectedOut, swapAmount, "Expected output should be less than input due to fees");
            
            console.log("=== testGetAmountOut passed ===");
        } catch Error(string memory reason) {
            console.log("ERROR: getAmountOut reverted with:", reason);
            revert(reason);
        } catch (bytes memory lowLevelData) {
            console.log("ERROR: getAmountOut failed with low-level error");
            console.logBytes(lowLevelData);
            revert("getAmountOut failed");
        }
    }
    
    function testRemoveLiquidity() public {
        // Add liquidity first
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1000 * 1e6;
        amounts[1] = 1000 * 1e6;
        amounts[2] = 1000 * 1e6;
        amounts[3] = 1000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        uint256 tickIndex = pool.addLiquidity(amounts, 500 * 1e6);
        
        // Record balances before removal
        uint256 balanceBeforeA = tokenA.balanceOf(user1);
        uint256 balanceBeforeB = tokenB.balanceOf(user1);
        
        // Remove 50% of liquidity
        uint256 fraction = 5e17; // 0.5 in 1e18 scale
        uint256[] memory returnedAmounts = pool.removeLiquidity(tickIndex, fraction);
        
        uint256 balanceAfterA = tokenA.balanceOf(user1);
        uint256 balanceAfterB = tokenB.balanceOf(user1);
        
        // Verify tokens were returned
        assertGt(balanceAfterA, balanceBeforeA);
        assertGt(balanceAfterB, balanceBeforeB);
        assertGt(returnedAmounts[0], 0);
        assertGt(returnedAmounts[1], 0);
        
        vm.stopPrank();
    }
    
    function testGetSpotPrice() public {
        // Add liquidity
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1000 * 1e6;
        amounts[1] = 2000 * 1e6; // Different amounts to create price difference
        amounts[2] = 1000 * 1e6;
        amounts[3] = 1000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        pool.addLiquidity(amounts, 1000 * 1e6);
        vm.stopPrank();
        
        // Get spot price
        uint256 priceAB = pool.getSpotPrice(0, 1);
        uint256 priceBA = pool.getSpotPrice(1, 0);
        
        assertGt(priceAB, 0);
        assertGt(priceBA, 0);
        
        // Prices should be inversely related (approximately)
        uint256 product = (priceAB * priceBA) / 1e6;
        assertApproxEqRel(product, 1e6, 1e5); // Within 10% due to AMM curve
    }
    
    function testTickEfficiency() public {
        // Add liquidity
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1000 * 1e6;
        amounts[1] = 1000 * 1e6;
        amounts[2] = 1000 * 1e6;
        amounts[3] = 1000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        uint256 tickIndex = pool.addLiquidity(amounts, 500 * 1e6);
        vm.stopPrank();
        
        uint256 efficiency = pool.getTickEfficiency(tickIndex);
        assertGt(efficiency, 0);
    }
    
    function testOwnerFunctions() public {
        // Test setting swap fee
        vm.prank(owner);
        pool.setSwapFee(50); // 0.5%
        assertEq(pool.swapFee(), 50);
        
        // Test non-owner cannot set fee
        vm.prank(user1);
        vm.expectRevert();
        pool.setSwapFee(25);
    }
    
    function testRevertInvalidAmountsLength() public {
        vm.startPrank(user1);
        
        // Wrong amounts array length
        uint256[] memory amounts = new uint256[](3); // Should be 4
        amounts[0] = 1000 * 1e6;
        amounts[1] = 1000 * 1e6;
        amounts[2] = 1000 * 1e6;
        
        vm.expectRevert("Invalid amounts length");
        pool.addLiquidity(amounts, 500 * 1e6);
        vm.stopPrank();
    }
    
    function testRevertZeroLiquidity() public {
        vm.startPrank(user1);
        
        uint256[] memory amounts = new uint256[](4);
        // All zeros - should fail
        
        vm.expectRevert("Zero liquidity");
        pool.addLiquidity(amounts, 0);
        vm.stopPrank();
    }
    
    function testRevertInvalidPlaneConstant() public {
        vm.startPrank(user1);
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1000 * 1e6;
        amounts[1] = 1000 * 1e6;
        amounts[2] = 1000 * 1e6;
        amounts[3] = 1000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        // Plane constant greater than radius should fail
        vm.expectRevert("Invalid plane constant");
        pool.addLiquidity(amounts, 3000 * 1e6);
        vm.stopPrank();
    }
    
    function testRevertSameTokenSwap() public {
        // Add liquidity first
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1000 * 1e6;
        amounts[1] = 1000 * 1e6;
        amounts[2] = 1000 * 1e6;
        amounts[3] = 1000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        pool.addLiquidity(amounts, 500 * 1e6);
        vm.stopPrank();
        
        // Try to swap same token
        vm.startPrank(user2);
        tokenA.approve(address(pool), 100 * 1e6);
        vm.expectRevert("Same token");
        pool.swap(0, 0, 100 * 1e6, 1); // Same token index
        vm.stopPrank();
    }

    // ===== MULTIPLE SWAP SLIPPAGE TESTS =====
    
    function testMultipleSwapsSlippageControl() public {
        // Add initial liquidity
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 10000 * 1e6; // 10,000 tokens each
        amounts[1] = 10000 * 1e6;
        amounts[2] = 10000 * 1e6;
        amounts[3] = 10000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        pool.addLiquidity(amounts, 5000 * 1e6);
        vm.stopPrank();
        
        // Get initial spot prices
        uint256 initialPriceAB = pool.getSpotPrice(0, 1);
        uint256 initialPriceBC = pool.getSpotPrice(1, 2);
        uint256 initialPriceCD = pool.getSpotPrice(2, 3);
        
        console.log("Initial prices:");
        console.log("  A/B:", initialPriceAB);
        console.log("  B/C:", initialPriceBC);
        console.log("  C/D:", initialPriceCD);
        
        // Perform multiple swaps in sequence
        vm.startPrank(user2);
        
        // Swap 1: A -> B
        uint256 swap1Amount = 100 * 1e6; // 100 tokens
        tokenA.approve(address(pool), swap1Amount);
        uint256 amountOut1 = pool.swap(0, 1, swap1Amount, 0);
        console.log("Swap 1 (A->B):", swap1Amount, "->", amountOut1);
        
        // Swap 2: B -> C
        uint256 swap2Amount = 50 * 1e6; // 50 tokens
        tokenB.approve(address(pool), swap2Amount);
        uint256 amountOut2 = pool.swap(1, 2, swap2Amount, 0);
        console.log("Swap 2 (B->C):", swap2Amount, "->", amountOut2);
        
        // Swap 3: C -> D
        uint256 swap3Amount = 25 * 1e6; // 25 tokens
        tokenC.approve(address(pool), swap3Amount);
        uint256 amountOut3 = pool.swap(2, 3, swap3Amount, 0);
        console.log("Swap 3 (C->D):", swap3Amount, "->", amountOut3);
        
        vm.stopPrank();
        
        // Get final spot prices
        uint256 finalPriceAB = pool.getSpotPrice(0, 1);
        uint256 finalPriceBC = pool.getSpotPrice(1, 2);
        uint256 finalPriceCD = pool.getSpotPrice(2, 3);
        
        console.log("Final prices:");
        console.log("  A/B:", finalPriceAB);
        console.log("  B/C:", finalPriceBC);
        console.log("  C/D:", finalPriceCD);
        
        // Calculate price changes and slippage
        uint256 slippageAB = _calculateSlippage(initialPriceAB, finalPriceAB);
        uint256 slippageBC = _calculateSlippage(initialPriceBC, finalPriceBC);
        uint256 slippageCD = _calculateSlippage(initialPriceCD, finalPriceCD);
        
        console.log("Slippage percentages:");
        console.log("  A/B:", slippageAB, "%");
        console.log("  B/C:", slippageBC, "%");
        console.log("  C/D:", slippageCD, "%");
        
        // Assert slippage is reasonable (less than 2% for multiple swaps)
        assertLt(slippageAB, 200, "Slippage A/B should be less than 2%");
        assertLt(slippageBC, 200, "Slippage B/C should be less than 2%");
        assertLt(slippageCD, 200, "Slippage C/D should be less than 2%");
        
        // Log slippage analysis
        console.log("Slippage Analysis:");
        console.log("  A/B: High slippage due to multiple swaps affecting same pair");
        console.log("  B/C: Moderate slippage due to intermediate swap");
        console.log("  C/D: Low slippage due to single swap");
    }
    
    function testLargeSwapSlippageControl() public {
        // Add substantial liquidity
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100000 * 1e6; // 100,000 tokens each
        amounts[1] = 100000 * 1e6;
        amounts[2] = 100000 * 1e6;
        amounts[3] = 100000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        pool.addLiquidity(amounts, 50000 * 1e6);
        vm.stopPrank();
        
        // Get initial price
        uint256 initialPrice = pool.getSpotPrice(0, 1);
        console.log("Initial A/B price:", initialPrice);
        
        // Perform large swap
        vm.startPrank(user2);
        uint256 largeSwapAmount = 1000 * 1e6; // 1,000 tokens (1% of liquidity)
        tokenA.approve(address(pool), largeSwapAmount);
        
        uint256 amountOut = pool.swap(0, 1, largeSwapAmount, 0);
        console.log("Large swap (A->B):", largeSwapAmount, "->", amountOut);
        vm.stopPrank();
        
        // Get final price
        uint256 finalPrice = pool.getSpotPrice(0, 1);
        console.log("Final A/B price:", finalPrice);
        
        // Calculate slippage
        uint256 slippage = _calculateSlippage(initialPrice, finalPrice);
        console.log("Large swap slippage:", slippage, "%");
        
        // Assert slippage is less than 1%
        assertLt(slippage, 100, "Large swap slippage should be less than 1%");
    }
    
    function testSingleSwapSlippageControl() public {
        // Add liquidity
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 50000 * 1e6; // 50,000 tokens each
        amounts[1] = 50000 * 1e6;
        amounts[2] = 50000 * 1e6;
        amounts[3] = 50000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        pool.addLiquidity(amounts, 25000 * 1e6);
        vm.stopPrank();
        
        // Test single swap A -> B
        uint256 initialPrice = pool.getSpotPrice(0, 1);
        console.log("Initial A/B price:", initialPrice);
        
        vm.startPrank(user2);
        uint256 swapAmount = 100 * 1e6; // 100 tokens (0.2% of liquidity)
        tokenA.approve(address(pool), swapAmount);
        
        uint256 amountOut = pool.swap(0, 1, swapAmount, 0);
        console.log("Single swap (A->B):", swapAmount, "->", amountOut);
        vm.stopPrank();
        
        uint256 finalPrice = pool.getSpotPrice(0, 1);
        console.log("Final A/B price:", finalPrice);
        
        uint256 slippage = _calculateSlippage(initialPrice, finalPrice);
        console.log("Single swap slippage:", slippage, "%");
        
        // Single swaps should have very low slippage (< 0.5%)
        assertLt(slippage, 50, "Single swap slippage should be less than 0.5%");
    }
    
    function testConsecutiveSmallSwapsSlippage() public {
        // Add liquidity
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 50000 * 1e6; // 50,000 tokens each
        amounts[1] = 50000 * 1e6;
        amounts[2] = 50000 * 1e6;
        amounts[3] = 50000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        pool.addLiquidity(amounts, 25000 * 1e6);
        vm.stopPrank();
        
        uint256 initialPrice = pool.getSpotPrice(0, 1);
        console.log("Initial A/B price:", initialPrice);
        
        // Perform 10 consecutive small swaps
        vm.startPrank(user2);
        uint256 totalSlippage = 0;
        
        for (uint256 i = 0; i < 10; i++) {
            uint256 swapAmount = 10 * 1e6; // 10 tokens each
            tokenA.approve(address(pool), swapAmount);
            
            uint256 amountOut = pool.swap(0, 1, swapAmount, 0);
            console.log("Swap", i + 1);
            console.log("(A->B):", swapAmount, "->", amountOut);
            
            // Calculate cumulative slippage
            uint256 currentPrice = pool.getSpotPrice(0, 1);
            uint256 slippage = _calculateSlippage(initialPrice, currentPrice);
            totalSlippage = slippage;
            
            console.log("  Cumulative slippage:", slippage, "%");
        }
        vm.stopPrank();
        
        uint256 finalPrice = pool.getSpotPrice(0, 1);
        uint256 finalSlippage = _calculateSlippage(initialPrice, finalPrice);
        
        console.log("Final A/B price:", finalPrice);
        console.log("Final cumulative slippage:", finalSlippage, "%");
        
        // Assert final slippage is less than 1%
        assertLt(finalSlippage, 100, "Cumulative slippage should be less than 1%");
    }
    
    function testBidirectionalSwapSlippage() public {
        // Add liquidity
        vm.startPrank(user1);
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 75000 * 1e6; // 75,000 tokens each
        amounts[1] = 75000 * 1e6;
        amounts[2] = 75000 * 1e6;
        amounts[3] = 75000 * 1e6;
        
        tokenA.approve(address(pool), amounts[0]);
        tokenB.approve(address(pool), amounts[1]);
        tokenC.approve(address(pool), amounts[2]);
        tokenD.approve(address(pool), amounts[3]);
        
        pool.addLiquidity(amounts, 37500 * 1e6);
        vm.stopPrank();
        
        uint256 initialPriceAB = pool.getSpotPrice(0, 1);
        uint256 initialPriceBA = pool.getSpotPrice(1, 0);
        console.log("Initial A/B price:", initialPriceAB);
        console.log("Initial B/A price:", initialPriceBA);
        
        // Forward swap: A -> B
        vm.startPrank(user2);
        uint256 forwardAmount = 500 * 1e6;
        tokenA.approve(address(pool), forwardAmount);
        uint256 forwardOut = pool.swap(0, 1, forwardAmount, 0);
        console.log("Forward swap (A->B):", forwardAmount, "->", forwardOut);
        vm.stopPrank();
        
        uint256 midPriceAB = pool.getSpotPrice(0, 1);
        uint256 slippageForward = _calculateSlippage(initialPriceAB, midPriceAB);
        console.log("Forward swap slippage:", slippageForward, "%");
        
        // Reverse swap: B -> A
        vm.startPrank(user3);
        uint256 reverseAmount = 500 * 1e6;
        tokenB.approve(address(pool), reverseAmount);
        uint256 reverseOut = pool.swap(1, 0, reverseAmount, 0);
        console.log("Reverse swap (B->A):", reverseAmount, "->", reverseOut);
        vm.stopPrank();
        
        uint256 finalPriceAB = pool.getSpotPrice(0, 1);
        uint256 slippageReverse = _calculateSlippage(midPriceAB, finalPriceAB);
        uint256 totalSlippage = _calculateSlippage(initialPriceAB, finalPriceAB);
        
        console.log("Reverse swap slippage:", slippageReverse, "%");
        console.log("Total bidirectional slippage:", totalSlippage, "%");
        
        // Assert slippages are reasonable
        assertLt(slippageForward, 100, "Forward swap slippage should be less than 1%");
        assertLt(slippageReverse, 100, "Reverse swap slippage should be less than 1%");
        assertLt(totalSlippage, 150, "Total bidirectional slippage should be less than 1.5%");
    }
    
    // Helper function to calculate slippage percentage (in basis points)
    function _calculateSlippage(uint256 initialPrice, uint256 finalPrice) internal pure returns (uint256) {
        if (initialPrice == 0) return 0;
        
        uint256 priceChange;
        if (finalPrice > initialPrice) {
            priceChange = finalPrice - initialPrice;
        } else {
            priceChange = initialPrice - finalPrice;
        }
        
        // Convert to basis points (1% = 100 basis points)
        return (priceChange * 10000) / initialPrice;
    }
}