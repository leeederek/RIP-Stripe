// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/OrbitalTypes.sol";

/// @title IOrbitalPool
/// @notice Unified interface for the Orbital AMM Pool combining N-token routing and multi-dimensional AMM functionality
/// @dev Pool implementations should support both index-based token access for cross-chain routing and full AMM features
interface IOrbitalPool {
    /// @notice Emitted when a swap is executed
    event Swap(
        address indexed trader,
        uint256 tokenInIndex,
        uint256 tokenOutIndex,
        uint256 amountIn,
        uint256 amountOut,
        uint256[] newReserves
    );

    /// @notice Emitted when fees are collected
    event FeesCollected(
        address indexed recipient,
        uint256[] amounts
    );

    /// @notice Emitted when liquidity is added
    event LiquidityAdded(
        address indexed provider,
        uint256[] amounts,
        uint256 lpTokensMinted,
        uint256[] newReserves
    );

    /// @notice Emitted when liquidity is removed
    event LiquidityRemoved(
        address indexed provider,
        uint256[] amounts,
        uint256 lpTokensBurned,
        uint256[] newReserves
    );

    // ========== N-Token Pool Functions (for RouterOFT compatibility) ==========

    /// @notice Execute a swap using token indices
    /// @param tokenInIndex Index of the input token in the pool
    /// @param tokenOutIndex Index of the output token in the pool
    /// @param amountIn Amount of input tokens
    /// @param minAmountOut Minimum acceptable output amount
    /// @param recipient Address to receive output tokens
    /// @return amountOut Actual output amount
    function swapExactIn(
        uint8 tokenInIndex,
        uint8 tokenOutIndex,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external returns (uint256 amountOut);

    /// @notice Get a quote for a swap without executing
    /// @param tokenInIndex Index of the input token
    /// @param tokenOutIndex Index of the output token
    /// @param amountIn Amount of input tokens
    /// @return amountOut Expected output amount
    function getQuote(
        uint8 tokenInIndex,
        uint8 tokenOutIndex,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    /// @notice Get the address of a token by its index
    /// @param index Token index in the pool
    /// @return token Token address
    function tokens(uint256 index) external view returns (address token);

    /// @notice Get the total number of tokens in the pool
    /// @return count Number of tokens
    function tokenCount() external view returns (uint256 count);

    /// @notice Get the current reserves for all tokens
    /// @return reserves Array of token reserves
    function totalReserves() external view returns (uint256[] memory reserves);

    // ========== Orbital Pool Functions ==========

    /// @notice Add liquidity with specified depeg protection
    /// @param amounts Token amounts to deposit (or empty for balanced deposit)
    /// @param capital Total capital if amounts not specified
    /// @param depegTolerance Minimum acceptable price (e.g., 0.99 = 99%)
    /// @param feeBps Fee in basis points (e.g., 30 = 0.30%)
    /// @return result Liquidity addition result with tick ID and parameters
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 capital,
        uint256 depegTolerance,
        uint256 feeBps
    ) external returns (OrbitalTypes.LiquidityResult memory result);

    /// @notice Remove liquidity and collect fees
    /// @param tickId Tick to remove
    /// @return amounts Token amounts returned
    /// @return fees Accrued fees collected
    function removeLiquidity(
        uint256 tickId
    ) external returns (
        uint256[] memory amounts,
        uint256[] memory fees
    );

    /// @notice Get pool statistics
    /// @return Pool statistics including token symbols, tick counts, reserves and liquidity
    function getPoolStats() external view returns (OrbitalTypes.PoolStats memory);

    /// @notice Collect accrued fees for a tick
    /// @param tickId Tick to collect fees from
    function collectFees(uint256 tickId) external;

    /// @notice Execute swap with address-based tokens (actual implementation)
    /// @param tokenIn Input token address
    /// @param tokenOut Output token address
    /// @param amountIn Input amount
    /// @param minAmountOut Minimum output amount
    /// @param deadline Transaction deadline
    /// @return result Trade execution result
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external returns (OrbitalTypes.TradeResult memory result);
}