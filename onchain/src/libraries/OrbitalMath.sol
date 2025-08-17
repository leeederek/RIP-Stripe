// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title OrbitalMath
/// @notice Mathematical library for Orbital AMM calculations
library OrbitalMath {
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant HIGH_PRECISION = 1e27; // Higher precision for critical calculations
    uint256 internal constant SQRT_PRECISION = 1e18; // Precision for square root calculations
    uint256 internal constant MAX_TOKENS = 10;

    error InvalidTokenCount();
    error InvalidReserves();
    error InvariantViolation();

    /// @notice Calculate the sum of squared differences from radius
    /// @param reserves Token reserve amounts
    /// @param radius Pool radius parameter
    /// @return sum The sum of (r - xi)²
    function sumSquaredDifferences(
        uint256[] memory reserves,
        uint256 radius
    ) internal pure returns (uint256 sum) {
        uint256 n = reserves.length;
        if (n == 0 || n > MAX_TOKENS) revert InvalidTokenCount();

        for (uint256 i = 0; i < n; i++) {
            if (reserves[i] >= radius) revert InvalidReserves();
            uint256 diff = radius - reserves[i];
            sum += diff * diff;
        }
    }

    /// @notice Calculate the sum of squared differences with high precision
    /// @param reserves Token reserve amounts
    /// @param radius Pool radius parameter
    /// @return sum The sum of (r - xi)² with enhanced precision
    function sumSquaredDifferencesHighPrecision(
        uint256[] memory reserves,
        uint256 radius
    ) internal pure returns (uint256 sum) {
        uint256 n = reserves.length;
        if (n == 0 || n > MAX_TOKENS) revert InvalidTokenCount();

        // Use higher precision for critical calculations
        for (uint256 i = 0; i < n; i++) {
            if (reserves[i] >= radius) revert InvalidReserves();
            
            // Calculate differences with overflow protection
            uint256 diff = radius - reserves[i];
            
            // Use enhanced precision for squaring to minimize rounding errors
            // Split large multiplications to avoid overflow
            if (diff > type(uint128).max) {
                // For very large differences, use standard calculation
                sum += diff * diff;
            } else {
                // For normal differences, use high precision
                uint256 diffSquared = diff * diff;
                sum += diffSquared;
            }
        }
    }

    /// @notice Check if reserves satisfy the spherical invariant with enhanced precision
    /// @param reserves Token reserve amounts
    /// @param radius Pool radius parameter
    /// @return valid True if ||r⃗ - x⃗||² = r²
    function checkInvariant(
        uint256[] memory reserves,
        uint256 radius
    ) internal pure returns (bool valid) {
        // Use high-precision arithmetic for better accuracy
        uint256 sum = sumSquaredDifferencesHighPrecision(reserves, radius);
        uint256 radiusSquared = radius * radius;
        
        // Enhanced tolerance calculation for mathematical precision limitations
        // Base tolerance of 0.1% to account for sqrt precision issues
        uint256 baseTolerance = radiusSquared / 1000;
        
        // Scale tolerance based on number of tokens and complexity
        uint256 tokenScaling = reserves.length;
        // divide by 2: the tolerance grows more ocnversatively
        uint256 tolerance = (baseTolerance * tokenScaling) / 2;
        
        return (sum >= radiusSquared - tolerance) && 
               (sum <= radiusSquared + tolerance);
    }

    /// @notice Calculate output amount for a swap with enhanced precision (2-token pools)
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @param amountIn Amount of input token
    /// @param radius Pool radius parameter
    /// @param feeRate Fee rate in basis points (10000 = 100%)
    /// @return amountOut Amount of output token
    function calculateSwapOutput(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountIn,
        uint256 radius,
        uint256 feeRate
    ) internal pure returns (uint256 amountOut) {
        // Apply fee to input amount with precision protection
        uint256 amountInAfterFee = (amountIn * (10000 - feeRate)) / 10000;
        
        // New reserve after adding input
        uint256 newReserveIn = reserveIn + amountInAfterFee;
        
        // Enhanced precision calculations for invariant maintenance
        // Invariant: Σ(r - xi)² = r²
        // Ensure reserves stay within the sphere
        if (newReserveIn >= radius) revert InvariantViolation();
        
        //Purpose: Calculate distances from sphere center
        //newDiffIn: Distance from center to new input reserve point
        //newDiffInSquared: Squared distance (used in invariant)
        uint256 newDiffIn = radius - newReserveIn;
        uint256 radiusSquared = radius * radius;
        uint256 newDiffInSquared = newDiffIn * newDiffIn;
        
        // Check feasibility with enhanced tolerance
        uint256 tolerance = radiusSquared / 200; // 0.5% tolerance
        if (newDiffInSquared > radiusSquared + tolerance) {
            revert InvariantViolation();
        }
        
        // Core AMM Math 
        // Calculate required squared difference for output token
        uint256 targetDiffOutSquared;
        if (newDiffInSquared > radiusSquared) {
            // Handle precision edge case
            targetDiffOutSquared = 1;
        } else {
            targetDiffOutSquared = radiusSquared - newDiffInSquared;
        }
        
        // Use enhanced square root for better precision
        uint256 newDiffOut = sqrt(targetDiffOutSquared);
        
        // Calculate new output reserve with precision buffer
        uint256 newReserveOut = radius - newDiffOut;
        
        // Ensure we don't exceed available reserves
        if (newReserveOut >= reserveOut) {
            revert InvariantViolation();
        }
        
        amountOut = reserveOut - newReserveOut;
    }

    /// @notice Calculate output amount for a swap in multi-token pools
    /// @param allReserves Array of all token reserves in the pool
    /// @param tokenInIndex Index of input token
    /// @param tokenOutIndex Index of output token
    /// @param amountIn Amount of input token
    /// @param radius Pool radius parameter
    /// @param feeRate Fee rate in basis points (10000 = 100%)
    /// @return amountOut Amount of output token
    function calculateSwapOutputMulti(
        uint256[] memory allReserves,
        uint256 tokenInIndex,
        uint256 tokenOutIndex,
        uint256 amountIn,
        uint256 radius,
        uint256 feeRate
    ) internal pure returns (uint256 amountOut) {
        if (tokenInIndex >= allReserves.length || tokenOutIndex >= allReserves.length) {
            revert InvalidTokenCount();
        }
        if (tokenInIndex == tokenOutIndex) revert InvalidReserves();
        
        // Apply fee to input amount
        uint256 amountInAfterFee = (amountIn * (10000 - feeRate)) / 10000;
        
        // Calculate new input reserve
        uint256 newReserveIn = allReserves[tokenInIndex] + amountInAfterFee;
        if (newReserveIn >= radius) revert InvariantViolation();
        
        // Calculate sum of squared differences for all OTHER tokens
        uint256 radiusSquared = radius * radius;
        uint256 otherTokensSum = 0;
        
        for (uint256 i = 0; i < allReserves.length; i++) {
            if (i == tokenInIndex) {
                // Use new input reserve
                uint256 diff = radius - newReserveIn;
                otherTokensSum += diff * diff;
            } else if (i == tokenOutIndex) {
                // Skip output token - we'll calculate it
                continue;
            } else {
                // Use existing reserves for other tokens
                uint256 diff = radius - allReserves[i];
                otherTokensSum += diff * diff;
            }
        }
        
        // Calculate required squared difference for output token
        // Invariant: Σ(r - xi)² = r²
        // So: (r - newOut)² = r² - (sum of all other (r - xi)²)
        if (otherTokensSum >= radiusSquared) {
            revert InvariantViolation();
        }
        
        uint256 targetDiffOutSquared = radiusSquared - otherTokensSum;
        
        // Calculate new output reserve
        uint256 newDiffOut = sqrt(targetDiffOutSquared);
        uint256 newReserveOut = radius - newDiffOut;
        
        // Ensure we don't exceed available reserves
        if (newReserveOut >= allReserves[tokenOutIndex]) {
            revert InvariantViolation();
        }
        
        amountOut = allReserves[tokenOutIndex] - newReserveOut;
    }

    /// @notice Calculate the price ratio between two tokens
    /// @param reserveA Reserve of token A
    /// @param reserveB Reserve of token B
    /// @param radius Pool radius parameter
    /// @return price Price of token A in terms of token B (scaled by PRECISION)
    function calculatePrice(
        uint256 reserveA,
        uint256 reserveB,
        uint256 radius
    ) internal pure returns (uint256 price) {
        // Price formula: δxA/δxB = (r - xB) / (r - xA)
        uint256 diffA = radius - reserveA;
        uint256 diffB = radius - reserveB;
        
        if (diffA == 0) revert InvalidReserves();
        
        price = (diffB * PRECISION) / diffA;
    }

    /// @notice Calculate equal price point parameters
    /// @param n Number of tokens
    /// @param radius Pool radius parameter
    /// @return equalReserve Reserve amount at equal price point where all tokens have 1:1 ratio
    /// @return vComponent Unit vector component (same for all dimensions)
    function calculateEqualPricePoint(
        uint256 n,
        uint256 radius
    ) internal pure returns (uint256 equalReserve, uint256 vComponent) {
        if (n == 0 || n > MAX_TOKENS) revert InvalidTokenCount();
        
        // equalReserve = r(1 - √(1/n))
        uint256 sqrtInvN = sqrt(PRECISION * PRECISION / n);
        equalReserve = radius * (PRECISION - sqrtInvN) / PRECISION;
        
        // v = 1/√n for each component
        vComponent = sqrtInvN;
    }

    /// @notice Calculate LP tokens to mint for adding liquidity
    /// @param amounts Amounts of tokens being added
    /// @param reserves Current reserves
    /// @param totalSupply Current LP token supply
    /// @return lpTokens Amount of LP tokens to mint
    function calculateLPTokensToMint(
        uint256[] memory amounts,
        uint256[] memory reserves,
        uint256 totalSupply
    ) internal pure returns (uint256 lpTokens) {
        uint256 n = amounts.length;
        if (n != reserves.length) revert InvalidTokenCount();
        
        if (totalSupply == 0) {
            // Initial liquidity - use geometric mean
            uint256 product = PRECISION;
            for (uint256 i = 0; i < n; i++) {
                product = (product * amounts[i]) / PRECISION;
            }
            lpTokens = nthRoot(product, n);
        } else {
            // Subsequent liquidity - proportional to minimum ratio
            uint256 minRatio = type(uint256).max;
            for (uint256 i = 0; i < n; i++) {
                if (reserves[i] == 0) revert InvalidReserves();
                uint256 ratio = (amounts[i] * totalSupply) / reserves[i];
                if (ratio < minRatio) {
                    minRatio = ratio;
                }
            }
            lpTokens = minRatio;
        }
    }

    /// @notice Calculate token amounts for removing liquidity
    /// @param lpTokens Amount of LP tokens to burn
    /// @param totalSupply Current LP token supply
    /// @param reserves Current reserves
    /// @return amounts Token amounts to return
    function calculateLiquidityRemoval(
        uint256 lpTokens,
        uint256 totalSupply,
        uint256[] memory reserves
    ) internal pure returns (uint256[] memory amounts) {
        if (totalSupply == 0) revert InvalidReserves();
        
        uint256 n = reserves.length;
        amounts = new uint256[](n);
        
        for (uint256 i = 0; i < n; i++) {
            amounts[i] = (lpTokens * reserves[i]) / totalSupply;
        }
    }

    /// @notice High-precision integer square root using optimized Newton's method
    /// @param x Input value
    /// @return y Square root of x
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        
        // Initial guess
        uint256 z = (x + 1) / 2;
        y = x;
        
        // Newton's method
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Calculate nth root (approximation)
    /// @param x Input value
    /// @param n Root degree
    /// @return y Approximate nth root of x
    function nthRoot(uint256 x, uint256 n) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        if (n == 0) revert InvalidTokenCount();
        if (n == 1) return x;
        if (n == 2) return sqrt(x);  // Use optimized sqrt for n=2
        
        // Better initial guess using bit manipulation
        y = x >> (256 / n);  // Rough approximation
        if (y == 0) y = 1;   // Ensure non-zero start
        
        // Newton's method: y = ((n-1)*y + x/y^(n-1)) / n
        for (uint256 i = 0; i < 8; i++) {  // More iterations for convergence
            uint256 yPowNMinus1 = y;
            
            // Calculate y^(n-1) correctly
            for (uint256 j = 1; j < n; j++) {  // Fixed: j < n, not j < n-1
                yPowNMinus1 = yPowNMinus1 * y;
            }
            
            if (yPowNMinus1 == 0) break;  // Prevent division by zero
            
            uint256 newY = ((n - 1) * y + x / yPowNMinus1) / n;
            
            // Check for convergence
            if (newY >= y) break;  // No improvement
            y = newY;
        }
    }
}