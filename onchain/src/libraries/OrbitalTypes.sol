// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title OrbitalTypes
/// @notice Data structures for Orbital AMM following the Paradigm paper
/// @dev Matches the Python implementation's data structures
library OrbitalTypes {
    
    /// @notice Tick state enum
    enum TickState {
        INTERIOR,
        BOUNDARY
    }
    
    /// @notice Individual Orbital tick following paper specifications
    struct OrbitalTick {
        uint256 tickId;              // Unique tick identifier
        address owner;               // LP who owns this tick
        uint256 k;                   // Plane boundary parameter
        uint256 radius;              // Sphere radius r
        uint256[] reserves;          // Current token reserves
        uint256 liquidity;           // LP's liquidity amount
        TickState state;             // Interior or boundary
        uint256 feeBps;              // LP fee tier in basis points (e.g., 30 = 0.30%)
        uint256[] feesAccrued;       // Accrued fees per token
    }
    
    /// @notice Consolidated tick for efficient computation
    struct ConsolidatedTick {
        uint256[] reserves;          // Total reserves across ticks
        uint256 radius;              // Total radius
        bool isInterior;             // Whether this is interior tick consolidation
        uint256 k;                   // Effective k for boundary ticks
    }
    
    /// @notice Swap state for boundary crossing with segmentation
    struct SwapState {
        uint256[] reserves;          // Current reserves
        uint256 amountRemaining;     // Amount left to swap
        uint256 amountCalculated;    // Amount calculated so far
        uint256 currentTickLevel;    // Current tick state
        bool crossedBoundary;        // Whether boundary was crossed
    }
    
    /// @notice Result of liquidity addition
    struct LiquidityResult {
        uint256 tickId;              // Created tick ID
        uint256 kValue;              // Calculated k value
        uint256 radius;              // Tick radius
        uint256 depegProtection;     // Depeg tolerance used
        uint256 capitalEfficiency;   // Efficiency multiplier
        uint256 virtualReserves;     // Minimum reserves (x_min)
        uint256[] initialReserves;   // Starting reserves
        uint256 effectiveDeposit;    // Total deposit amount
        uint256[] leftoverAmounts;   // Unused token amounts
        bool success;                // Operation success
        string message;              // Error message if failed
    }
    
    /// @notice Trade execution result
    struct TradeResult {
        uint256 inputAmountGross;    // Total input including fees
        uint256 inputAmountNet;      // Input after fees
        uint256 outputAmount;        // Output token amount
        uint256 effectivePrice;      // Price achieved
        uint256 segments;            // Number of segments executed
        bool success;                // Operation success
        string message;              // Error message if failed
    }
    
    /// @notice Pool statistics
    struct PoolStats {
        string[] tokenSymbols;       // Token symbols
        uint256 totalTicks;          // Total number of ticks
        uint256 interiorTicks;       // Number of interior ticks
        uint256 boundaryTicks;       // Number of boundary ticks
        uint256[] totalReserves;     // Sum of all reserves
        uint256 totalLiquidity;      // Total liquidity provided
    }
    
    /// @notice Tick crossing info for boundary detection
    struct CrossingInfo {
        bool willCross;              // Whether crossing will occur
        uint256 crossingAmount;      // Amount that causes crossing
        uint256 crossingFraction;    // Fraction of trade at crossing
        TickState fromState;         // State before crossing
        TickState toState;           // State after crossing
        uint256 tickId;              // Tick that will cross
    }
    
    /// @notice Trade segment for multi-segment execution
    struct TradeSegment {
        uint256 grossInput;          // Gross input for segment
        uint256 netInput;            // Net input after fees
        uint256 output;              // Output amount
        uint256[] startReserves;     // Reserves at segment start
        uint256[] endReserves;       // Reserves at segment end
        bool causesCrossing;         // Whether this segment causes crossing
    }
}