// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Math.sol";
import {Math as OZMath} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title OrbitalCoreMath
/// @notice Core mathematical functions for Orbital AMM following the Paradigm paper
/// @dev Implements sphere constraint, polar decomposition, and k-value calculations
library OrbitalCoreMath {
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant SQRT_PRECISION = 1e9;
    uint256 internal constant BASIS_POINTS = 10000;
    
    /// @notice Verify sphere constraint: ||r⃗ - x⃗||² = r²
    /// @param reserves Current reserve amounts
    /// @param radius Sphere radius
    /// @return valid True if constraint is satisfied
    function verifySphereConstraint(
        uint256[] memory reserves,
        uint256 radius
    ) internal pure returns (bool valid) {
        uint256 n = reserves.length;
        uint256 sumSquaredDiffs = 0;
        
        // Calculate sum((r - x_i)²)
        for (uint256 i = 0; i < n; i++) {
            uint256 diff;
            if (radius > reserves[i]) {
                diff = radius - reserves[i];
            } else {
                diff = reserves[i] - radius;
            }
            
            // Scale to prevent overflow
            uint256 scaledDiff = diff / 1e9;
            sumSquaredDiffs += scaledDiff * scaledDiff;
        }
        
        // Compare with r²
        uint256 scaledRadius = radius / 1e9;
        uint256 radiusSquared = scaledRadius * scaledRadius;
        
        // Allow small tolerance for rounding errors
        uint256 tolerance = radiusSquared / 1000; // 0.1% tolerance
        
        if (sumSquaredDiffs > radiusSquared) {
            return sumSquaredDiffs - radiusSquared <= tolerance;
        } else {
            return radiusSquared - sumSquaredDiffs <= tolerance;
        }
    }
    
    /// @notice Calculate instantaneous price p_ij = (r - x_i) / (r - x_j)
    /// @param reserves Current reserves
    /// @param tokenI Token i index
    /// @param tokenJ Token j index
    /// @param radius Sphere radius
    /// @return price Price of token i in terms of token j
    function calculateSpherePrice(
        uint256[] memory reserves,
        uint256 tokenI,
        uint256 tokenJ,
        uint256 radius
    ) internal pure returns (uint256 price) {
        require(tokenI < reserves.length && tokenJ < reserves.length, "Invalid tokens");
        require(radius > reserves[tokenJ], "Invalid state");
        
        uint256 numerator = radius - reserves[tokenI];
        uint256 denominator = radius - reserves[tokenJ];
        
        return OZMath.mulDiv(numerator, PRECISION, denominator);
    }
    
    /// @notice Calculate equal price point: x_i = r(1 - 1/√n) for all i
    /// @param radius Sphere radius
    /// @param n Number of tokens
    /// @return equalReserve Reserve amount at equal price point
    function calculateEqualPricePoint(
        uint256 radius,
        uint256 n
    ) internal pure returns (uint256 equalReserve) {
        require(n > 0, "Invalid token count");
        
        // Calculate 1/√n with precision
        uint256 sqrtN = sqrt(n * PRECISION);
        uint256 oneOverSqrtN = OZMath.mulDiv(PRECISION, PRECISION, sqrtN);
        
        // r(1 - 1/√n)
        equalReserve = OZMath.mulDiv(radius, PRECISION - oneOverSqrtN, PRECISION);
    }
    
    /// @notice Polar decomposition: calculate α = x⃗ · v⃗ = sum(reserves) / √n
    /// @param reserves Current reserves
    /// @return alpha Projection magnitude
    /// @return wVector Orthogonal component (w⃗ = x⃗ - αv⃗)
    function polarDecompose(
        uint256[] memory reserves
    ) internal pure returns (uint256 alpha, uint256[] memory wVector) {
        uint256 n = reserves.length;
        require(n > 0, "Empty reserves");
        
        // Calculate sum of reserves
        uint256 sum = 0;
        for (uint256 i = 0; i < n; i++) {
            sum += reserves[i];
        }
        
        // α = sum / √n
        uint256 sqrtN = sqrt(n * PRECISION);
        alpha = OZMath.mulDiv(sum, PRECISION, sqrtN);
        
        // Calculate w⃗ = x⃗ - αv⃗
        wVector = new uint256[](n);
        uint256 vComponent = OZMath.mulDiv(alpha, PRECISION, sqrtN);
        
        for (uint256 i = 0; i < n; i++) {
            if (reserves[i] >= vComponent) {
                wVector[i] = reserves[i] - vComponent;
            } else {
                // Handle underflow case
                wVector[i] = 0;
            }
        }
    }
    
    /// @notice Calculate k-bounds for valid tick boundaries
    /// @param radius Sphere radius
    /// @param n Number of tokens
    /// @return kMin Minimum k value (r(√n - 1))
    /// @return kMax Maximum k value (r(n-1)/√n)
    function calculateKBounds(
        uint256 radius,
        uint256 n
    ) internal pure returns (uint256 kMin, uint256 kMax) {
        require(n > 0, "Invalid token count");
        
        uint256 sqrtN = sqrt(n * PRECISION);
        
        // k_min = r(√n - 1)
        if (sqrtN > PRECISION) {
            kMin = OZMath.mulDiv(radius, sqrtN - PRECISION, PRECISION);
        } else {
            kMin = 0;
        }
        
        // k_max = r(n-1)/√n
        if (n > 1) {
            kMax = OZMath.mulDiv(radius, (n - 1) * PRECISION, sqrtN);
        } else {
            kMax = 0;
        }
    }
    
    /// @notice Convert depeg tolerance to k-value
    /// @param depegPrice Minimum acceptable price (e.g., 0.95 = 95%)
    /// @param radius Sphere radius
    /// @param n Number of tokens
    /// @return k Tick boundary parameter
    function depegPriceToK(
        uint256 depegPrice,
        uint256 radius,
        uint256 n
    ) internal pure returns (uint256 k) {
        require(depegPrice <= PRECISION, "Invalid depeg price");
        
        (uint256 kMin, uint256 kMax) = calculateKBounds(radius, n);
        
        // Linear interpolation: higher depeg_price → k closer to kMin
        // Map depegPrice [0.8, 1.0] to [kMax, kMin]
        uint256 minPrice = (PRECISION * 80) / 100; // 0.8
        uint256 maxPrice = PRECISION; // 1.0
        
        if (depegPrice >= maxPrice) {
            return kMin;
        } else if (depegPrice <= minPrice) {
            return kMax;
        }
        
        // Normalize price to [0, 1]
        uint256 normalizedPrice = OZMath.mulDiv(
            depegPrice - minPrice,
            PRECISION,
            maxPrice - minPrice
        );
        
        // Interpolate: high normalized_price → low k
        k = kMin + OZMath.mulDiv(PRECISION - normalizedPrice, kMax - kMin, PRECISION);
    }
    
    /// @notice Calculate minimum reserves (virtual reserves) for a tick
    /// @param k Tick boundary parameter
    /// @param radius Sphere radius
    /// @param n Number of tokens
    /// @return xMin Minimum possible reserve
    function calculateXMin(
        uint256 k,
        uint256 radius,
        uint256 n
    ) internal pure returns (uint256 xMin) {
        uint256 sqrtN = sqrt(n * PRECISION);
        (uint256 kMin, uint256 kMax) = calculateKBounds(radius, n);
        
        // Clamp k to valid range
        if (k < kMin) k = kMin;
        if (k > kMax) k = kMax;
        
        uint256 equalPriceReserve = OZMath.mulDiv(radius, PRECISION, sqrtN);
        
        // Geometric interpolation
        // t = (k - kMin) / (kMax - kMin)
        uint256 t;
        if (kMax > kMin) {
            t = OZMath.mulDiv(k - kMin, PRECISION, kMax - kMin);
        } else {
            t = 0;
        }
        
        // From 70% of equal price (conservative) to 10% (aggressive)
        uint256 factor = (PRECISION * 70) / 100 - OZMath.mulDiv(t, (PRECISION * 60) / 100, PRECISION);
        xMin = OZMath.mulDiv(equalPriceReserve, factor, PRECISION);
    }
    
    /// @notice Calculate capital efficiency ratio
    /// @param k Tick boundary parameter
    /// @param radius Sphere radius
    /// @param n Number of tokens
    /// @return efficiency Capital efficiency multiplier
    function calculateCapitalEfficiency(
        uint256 k,
        uint256 radius,
        uint256 n
    ) internal pure returns (uint256 efficiency) {
        uint256 sqrtN = sqrt(n * PRECISION);
        uint256 xBase = OZMath.mulDiv(radius, PRECISION - OZMath.mulDiv(PRECISION, PRECISION, sqrtN), PRECISION);
        uint256 xMin = calculateXMin(k, radius, n);
        
        if (xBase <= xMin) {
            return type(uint256).max; // Perfect efficiency
        }
        
        return OZMath.mulDiv(xBase, PRECISION, xBase - xMin);
    }
    
    /// @notice Calculate torus invariant for global trades
    /// @param intReserves Interior tick reserves
    /// @param bndReserves Boundary tick reserves
    /// @param bndRadius Boundary tick radius
    /// @param n Number of tokens
    /// @return invariant Torus invariant value
    function calculateTorusInvariant(
        uint256[] memory intReserves,
        uint256[] memory bndReserves,
        uint256 bndRadius,
        uint256 n
    ) internal pure returns (uint256 invariant) {
        require(intReserves.length == n && bndReserves.length == n, "Invalid reserves");
        
        uint256 sqrtN = sqrt(n * PRECISION);
        
        // ||x_int||²
        uint256 intNormSquared = 0;
        for (uint256 i = 0; i < n; i++) {
            uint256 scaled = intReserves[i] / 1e9;
            intNormSquared += scaled * scaled;
        }
        
        // ||x_bnd||²
        uint256 bndNormSquared = 0;
        uint256 bndSum = 0;
        for (uint256 i = 0; i < n; i++) {
            uint256 scaled = bndReserves[i] / 1e9;
            bndNormSquared += scaled * scaled;
            bndSum += bndReserves[i];
        }
        
        // Penalty term: (α_bnd - r_bnd/√n)²
        uint256 penalty = 0;
        if (bndRadius > 0 && bndSum > 0) {
            uint256 alphaBnd = OZMath.mulDiv(bndSum, PRECISION, sqrtN);
            uint256 rOverSqrtN = OZMath.mulDiv(bndRadius, PRECISION, sqrtN);
            
            uint256 diff;
            if (alphaBnd > rOverSqrtN) {
                diff = (alphaBnd - rOverSqrtN) / 1e9;
            } else {
                diff = (rOverSqrtN - alphaBnd) / 1e9;
            }
            penalty = diff * diff;
        }
        
        // Scale back and combine
        invariant = (intNormSquared + bndNormSquared - penalty) * 1e18;
    }
    
    /// @notice Square root using Babylonian method
    /// @param x Input value
    /// @return result Square root
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        return OZMath.sqrt(x);
    }
}