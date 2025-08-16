// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./libraries/OrbitalCoreMath.sol";
import "./libraries/OrbitalTypes.sol";
import "./libraries/Math.sol";
import "./interfaces/IOrbitalPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title OrbitalPoolPaper
/// @notice Multi-token AMM with per-tick liquidity following the Paradigm Orbital paper
/// @dev Supports N tokens with individual tick management and dynamic boundary crossing
contract OrbitalPool is IOrbitalPool, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using OrbitalCoreMath for uint256[];
    using OrbitalCoreMath for uint256;
    using Math for uint256;
    
    // Pool configuration
    uint256 public immutable tokenCount;
    address[] public tokens;
    string[] public tokenSymbols;
    mapping(address => uint256) public tokenIndex;
    
    // Tick management
    mapping(uint256 => OrbitalTypes.OrbitalTick) public ticks;
    uint256 public nextTickId = 1;
    uint256[] public activeTickIds;
    mapping(uint256 => uint256) public tickIdToIndex;
    
    // State tracking
    mapping(uint256 => bool) public isInteriorTick;
    mapping(uint256 => bool) public isBoundaryTick;
    uint256[] public interiorTickIds;
    uint256[] public boundaryTickIds;
    
    // Pool state
    uint256[] internal _totalReserves;
    uint256 public totalLiquidity;
    
    // Constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant MAX_TOKENS = 10;
    uint256 private constant MIN_LIQUIDITY = 1e15; // Minimum liquidity to prevent dust
    
    // Events
    event LiquidityAdded(
        address indexed provider,
        uint256 indexed tickId,
        uint256 radius,
        uint256 k,
        uint256[] amounts,
        uint256 feeBps
    );
    
    event LiquidityRemoved(
        address indexed provider,
        uint256 indexed tickId,
        uint256[] amounts,
        uint256[] fees
    );
    
    event Swap(
        address indexed trader,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 segments
    );
    
    event BoundaryCrossed(
        uint256 indexed tickId,
        OrbitalTypes.TickState fromState,
        OrbitalTypes.TickState toState
    );
    
    event FeesCollected(
        uint256 indexed tickId,
        address indexed owner,
        uint256[] amounts
    );
    
    modifier validTokenIndex(uint256 index) {
        require(index < tokenCount, "Invalid token index");
        _;
    }
    
    modifier tickExists(uint256 tickId) {
        require(ticks[tickId].owner != address(0), "Tick does not exist");
        _;
    }
    
    constructor(
        address[] memory _tokens,
        string[] memory _symbols,
        address _owner
    ) Ownable(_owner) {
        require(_tokens.length >= 2 && _tokens.length <= MAX_TOKENS, "Invalid token count");
        require(_tokens.length == _symbols.length, "Mismatched arrays");
        
        tokenCount = _tokens.length;
        tokens = _tokens;
        tokenSymbols = _symbols;
        _totalReserves = new uint256[](tokenCount);
        
        // Setup token indices
        for (uint256 i = 0; i < tokenCount; i++) {
            require(_tokens[i] != address(0), "Invalid token address");
            tokenIndex[_tokens[i]] = i;
        }
        
        // Validate no duplicate tokens
        for (uint256 i = 0; i < tokenCount; i++) {
            for (uint256 j = i + 1; j < tokenCount; j++) {
                require(_tokens[i] != _tokens[j], "Duplicate tokens");
            }
        }
    }
    
    /// @notice Add liquidity with specified depeg protection
    /// @param amounts Token amounts to deposit (or empty for balanced deposit)
    /// @param capital Total capital if amounts not specified
    /// @param depegTolerance Minimum acceptable price (e.g., 0.99 = 99%)
    /// @param feeBps Fee in basis points (e.g., 30 = 0.30%)
    /// @return result Liquidity addition result
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 capital,
        uint256 depegTolerance,
        uint256 feeBps
    ) external nonReentrant returns (OrbitalTypes.LiquidityResult memory result) {
        require(feeBps <= 1000, "Fee too high"); // Max 10%
        require(depegTolerance >= 0.8e18 && depegTolerance <= PRECISION, "Invalid depeg tolerance");
        
        uint256[] memory deposits = new uint256[](tokenCount);
        uint256[] memory leftovers = new uint256[](tokenCount);
        uint256 perToken;
        uint256 radius;
        
        // Determine deposits
        if (amounts.length > 0) {
            require(amounts.length == tokenCount, "Invalid amounts length");
            
            // Find minimum for balanced deposit
            uint256 minAmount = type(uint256).max;
            for (uint256 i = 0; i < tokenCount; i++) {
                require(amounts[i] > 0, "Zero amount");
                if (amounts[i] < minAmount) minAmount = amounts[i];
            }
            
            perToken = minAmount;
            for (uint256 i = 0; i < tokenCount; i++) {
                deposits[i] = perToken;
                leftovers[i] = amounts[i] - perToken;
            }
        } else {
            require(capital > MIN_LIQUIDITY, "Insufficient capital");
            perToken = capital / tokenCount;
            for (uint256 i = 0; i < tokenCount; i++) {
                deposits[i] = perToken;
            }
        }
        
        // Calculate radius from balanced deposit
        // r = a / (1 - 1/√n) where a is per-token deposit
        // Since sqrt returns integer sqrt, we need to scale properly
        uint256 sqrtN = OrbitalCoreMath.sqrt(tokenCount * PRECISION);
        
        // sqrtN is approximately sqrt(tokenCount) * 1e9
        // We need to work in 1e18 precision
        uint256 scaledSqrtN = sqrtN * 1e9; // Convert to 1e18 precision
        
        require(scaledSqrtN > PRECISION, "Invalid sqrt result");
        radius = perToken.mulDiv(scaledSqrtN, scaledSqrtN - PRECISION);
        
        // Calculate k from depeg tolerance
        uint256 k = OrbitalCoreMath.depegPriceToK(depegTolerance, radius, tokenCount);
        
        // Validate k bounds
        (uint256 kMin, uint256 kMax) = OrbitalCoreMath.calculateKBounds(radius, tokenCount);
        require(k >= kMin && k <= kMax, "Invalid k value");
        
        // Transfer tokens
        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20(tokens[i]).safeTransferFrom(msg.sender, address(this), deposits[i]);
            _totalReserves[i] += deposits[i];
        }
        
        // Create tick with actual deposited amounts as reserves
        uint256 tickId = nextTickId++;
        ticks[tickId] = OrbitalTypes.OrbitalTick({
            tickId: tickId,
            owner: msg.sender,
            k: k,
            radius: radius,
            reserves: deposits,  // Use actual deposited amounts
            liquidity: perToken * tokenCount,
            state: OrbitalTypes.TickState.INTERIOR,
            feeBps: feeBps,
            feesAccrued: new uint256[](tokenCount)
        });
        
        // Verify sphere constraint with actual reserves
        require(
            OrbitalCoreMath.verifySphereConstraint(deposits, radius),
            "Initial reserves violate sphere constraint"
        );
        
        // Update tracking
        activeTickIds.push(tickId);
        tickIdToIndex[tickId] = activeTickIds.length - 1;
        interiorTickIds.push(tickId);
        isInteriorTick[tickId] = true;
        totalLiquidity += ticks[tickId].liquidity;
        
        // Calculate metrics
        uint256 xMin = OrbitalCoreMath.calculateXMin(k, radius, tokenCount);
        uint256 efficiency = OrbitalCoreMath.calculateCapitalEfficiency(k, radius, tokenCount);
        
        // Emit event
        emit LiquidityAdded(msg.sender, tickId, radius, k, deposits, feeBps);
        
        // Return result
        result = OrbitalTypes.LiquidityResult({
            tickId: tickId,
            kValue: k,
            radius: radius,
            depegProtection: depegTolerance,
            capitalEfficiency: efficiency,
            virtualReserves: xMin,
            initialReserves: deposits,  // Return actual deposited amounts
            effectiveDeposit: perToken * tokenCount,
            leftoverAmounts: leftovers,
            success: true,
            message: ""
        });
    }
    
    /// @notice Remove liquidity and collect fees
    /// @param tickId Tick to remove
    /// @return amounts Token amounts returned
    /// @return fees Accrued fees collected
    function removeLiquidity(
        uint256 tickId
    ) external nonReentrant tickExists(tickId) returns (
        uint256[] memory amounts,
        uint256[] memory fees
    ) {
        OrbitalTypes.OrbitalTick storage tick = ticks[tickId];
        require(tick.owner == msg.sender, "Not tick owner");
        
        amounts = new uint256[](tokenCount);
        fees = tick.feesAccrued;
        
        // Calculate proportional share of reserves
        uint256 tickLiquidity = tick.liquidity;
        if (totalLiquidity > 0) {
            for (uint256 i = 0; i < tokenCount; i++) {
                amounts[i] = _totalReserves[i].mulDiv(tickLiquidity, totalLiquidity);
                _totalReserves[i] -= amounts[i];
            }
        }
        
        // Transfer tokens and fees
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 total = amounts[i] + fees[i];
            if (total > 0) {
                IERC20(tokens[i]).safeTransfer(msg.sender, total);
            }
        }
        
        // Remove tick from tracking
        _removeTickFromTracking(tickId);
        totalLiquidity -= tickLiquidity;
        
        // Delete tick
        delete ticks[tickId];
        
        emit LiquidityRemoved(msg.sender, tickId, amounts, fees);
    }
    
    /// @notice Execute swap with boundary crossing detection
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
    ) external nonReentrant returns (OrbitalTypes.TradeResult memory result) {
        require(block.timestamp <= deadline, "Expired");
        require(tokenIn != tokenOut, "Same token");
        require(amountIn > 0, "Zero input");
        
        uint256 inputIdx = tokenIndex[tokenIn];
        uint256 outputIdx = tokenIndex[tokenOut];
        require(inputIdx < tokenCount && outputIdx < tokenCount, "Invalid token");
        
        // Transfer input tokens
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        
        // Execute trade with segmentation
        (uint256 outputAmount, uint256 segments) = _executeTradeWithSegmentation(
            inputIdx,
            outputIdx,
            amountIn
        );
        
        require(outputAmount >= minAmountOut, "Insufficient output");
        
        // Transfer output tokens
        IERC20(tokenOut).safeTransfer(msg.sender, outputAmount);
        
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, outputAmount, segments);
        
        result = OrbitalTypes.TradeResult({
            inputAmountGross: amountIn,
            inputAmountNet: amountIn, // Will be calculated with fees
            outputAmount: outputAmount,
            effectivePrice: outputAmount.mulDiv(PRECISION, amountIn),
            segments: segments,
            success: true,
            message: ""
        });
    }
    
    /// @notice Execute swap using token indices (INTokenPool interface)
    /// @param tokenInIndex Index of input token
    /// @param tokenOutIndex Index of output token
    /// @param amountIn Input amount
    /// @param minAmountOut Minimum output amount
    /// @param recipient Address to receive output tokens
    /// @return amountOut Actual output amount
    function swapExactIn(
        uint8 tokenInIndex,
        uint8 tokenOutIndex,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external override nonReentrant returns (uint256 amountOut) {
        require(tokenInIndex < tokenCount, "Invalid input index");
        require(tokenOutIndex < tokenCount, "Invalid output index");
        require(tokenInIndex != tokenOutIndex, "Same token");
        require(amountIn > 0, "Zero input");
        require(recipient != address(0), "Invalid recipient");
        
        address tokenIn = tokens[tokenInIndex];
        address tokenOut = tokens[tokenOutIndex];
        
        // Transfer input tokens from sender
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        
        // Execute trade with segmentation
        (uint256 outputAmount, ) = _executeTradeWithSegmentation(
            tokenInIndex,
            tokenOutIndex,
            amountIn
        );
        
        require(outputAmount >= minAmountOut, "Insufficient output");
        
        // Transfer output tokens to recipient
        IERC20(tokenOut).safeTransfer(recipient, outputAmount);
        
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, outputAmount, 1);
        
        return outputAmount;
    }
    
    /// @notice Get quote for swap without executing (INTokenPool interface)
    /// @param tokenInIndex Index of input token
    /// @param tokenOutIndex Index of output token
    /// @param amountIn Input amount
    /// @return amountOut Expected output amount
    function getQuote(
        uint8 tokenInIndex,
        uint8 tokenOutIndex,
        uint256 amountIn
    ) external view override returns (uint256 amountOut) {
        require(tokenInIndex < tokenCount, "Invalid input index");
        require(tokenOutIndex < tokenCount, "Invalid output index");
        require(tokenInIndex != tokenOutIndex, "Same token");
        require(amountIn > 0, "Zero input");
        
        // Simplified quote calculation - in production this would simulate the full trade
        // For now, using a basic approximation based on current reserves
        uint256 inputReserve = _totalReserves[tokenInIndex];
        uint256 outputReserve = _totalReserves[tokenOutIndex];
        
        if (inputReserve == 0 || outputReserve == 0) {
            return 0;
        }
        
        // Apply fee (using average fee of 30 bps for quote)
        uint256 amountInWithFee = amountIn * 9970 / 10000;
        
        // Simple constant product formula for quote
        // In production, this should use the actual orbital math
        amountOut = (amountInWithFee * outputReserve) / (inputReserve + amountInWithFee);
    }
    
    /// @notice Internal function to execute trade with boundary crossing segmentation
    function _executeTradeWithSegmentation(
        uint256 inputIdx,
        uint256 outputIdx,
        uint256 totalInput
    ) internal returns (uint256 totalOutput, uint256 segments) {
        uint256 remainingInput = totalInput;
        segments = 0;
        
        while (remainingInput > 0 && segments < 10) { // Max 10 segments for safety
            segments++;
            
            // Consolidate current ticks
            (
                OrbitalTypes.ConsolidatedTick memory intTick,
                OrbitalTypes.ConsolidatedTick memory bndTick
            ) = _consolidateTicks();
            
            // Calculate current invariant
            uint256 currentInvariant = OrbitalCoreMath.calculateTorusInvariant(
                intTick.reserves,
                bndTick.reserves,
                bndTick.radius,
                tokenCount
            );
            
            // Try full remaining amount
            (uint256 segmentOutput, bool causesCrossing, uint256 crossingTickId) = 
                _simulateTrade(inputIdx, outputIdx, remainingInput, currentInvariant);
            
            if (!causesCrossing) {
                // Execute full trade in current configuration
                _applyTrade(inputIdx, outputIdx, remainingInput, segmentOutput);
                totalOutput += segmentOutput;
                remainingInput = 0;
            } else {
                // Find crossing point and execute partial trade
                uint256 crossingAmount = _findCrossingAmount(
                    inputIdx,
                    outputIdx,
                    remainingInput,
                    crossingTickId,
                    currentInvariant
                );
                
                if (crossingAmount > 0) {
                    (uint256 partialOutput,,) = _simulateTrade(
                        inputIdx,
                        outputIdx,
                        crossingAmount,
                        currentInvariant
                    );
                    
                    _applyTrade(inputIdx, outputIdx, crossingAmount, partialOutput);
                    totalOutput += partialOutput;
                    remainingInput -= crossingAmount;
                    
                    // Flip tick state
                    _flipTickState(crossingTickId);
                }
            }
        }
    }
    
    /// @notice Consolidate ticks by state
    function _consolidateTicks() internal view returns (
        OrbitalTypes.ConsolidatedTick memory intTick,
        OrbitalTypes.ConsolidatedTick memory bndTick
    ) {
        uint256[] memory intReserves = new uint256[](tokenCount);
        uint256[] memory bndReserves = new uint256[](tokenCount);
        uint256 intRadius;
        uint256 bndRadius;
        uint256 bndKSum;
        uint256 bndCount;
        
        // Aggregate interior ticks
        for (uint256 i = 0; i < interiorTickIds.length; i++) {
            OrbitalTypes.OrbitalTick storage tick = ticks[interiorTickIds[i]];
            intRadius += tick.radius;
            for (uint256 j = 0; j < tokenCount; j++) {
                intReserves[j] += tick.reserves[j];
            }
        }
        
        // Aggregate boundary ticks
        for (uint256 i = 0; i < boundaryTickIds.length; i++) {
            OrbitalTypes.OrbitalTick storage tick = ticks[boundaryTickIds[i]];
            bndRadius += tick.radius;
            bndKSum += tick.k;
            bndCount++;
            for (uint256 j = 0; j < tokenCount; j++) {
                bndReserves[j] += tick.reserves[j];
            }
        }
        
        intTick = OrbitalTypes.ConsolidatedTick({
            reserves: intReserves,
            radius: intRadius,
            isInterior: true,
            k: 0
        });
        
        bndTick = OrbitalTypes.ConsolidatedTick({
            reserves: bndReserves,
            radius: bndRadius,
            isInterior: false,
            k: bndCount > 0 ? bndKSum / bndCount : 0
        });
    }
    
    /// @notice Simulate trade to check for boundary crossing
    function _simulateTrade(
        uint256, // inputIdx
        uint256, // outputIdx
        uint256 inputAmount,
        uint256 // targetInvariant
    ) internal view returns (uint256 outputAmount, bool causesCrossing, uint256 crossingTickId) {
        // This is a simplified version - full implementation would:
        // 1. Apply proportional input/output across all ticks
        // 2. Check each tick's new alpha vs its k value
        // 3. Use Newton's method to solve for output maintaining invariant
        
        // For now, return simplified calculation
        outputAmount = inputAmount * 95 / 100; // Placeholder
        causesCrossing = false;
        crossingTickId = 0;
    }
    
    /// @notice Find the exact amount that causes boundary crossing
    function _findCrossingAmount(
        uint256 inputIdx,
        uint256 outputIdx,
        uint256 maxAmount,
        uint256, // crossingTickId
        uint256 targetInvariant
    ) internal view returns (uint256) {
        // Binary search for crossing point
        uint256 low = 0;
        uint256 high = maxAmount;
        uint256 tolerance = maxAmount / 1000; // 0.1% tolerance
        
        while (high - low > tolerance) {
            uint256 mid = (low + high) / 2;
            
            (,bool crosses,) = _simulateTrade(inputIdx, outputIdx, mid, targetInvariant);
            
            if (crosses) {
                high = mid;
            } else {
                low = mid;
            }
        }
        
        return low;
    }
    
    /// @notice Apply trade to all ticks proportionally
    function _applyTrade(
        uint256 inputIdx,
        uint256 outputIdx,
        uint256 inputAmount,
        uint256 outputAmount
    ) internal {
        uint256 totalActiveLiquidity = _getActiveLiquidity();
        
        for (uint256 i = 0; i < activeTickIds.length; i++) {
            uint256 tickId = activeTickIds[i];
            OrbitalTypes.OrbitalTick storage tick = ticks[tickId];
            
            // Calculate tick's proportion
            uint256 proportion = tick.liquidity.mulDiv(PRECISION, totalActiveLiquidity);
            
            // Apply fees
            uint256 feeAmount = inputAmount.mulDiv(tick.feeBps, BASIS_POINTS);
            uint256 netInput = inputAmount - feeAmount;
            
            // Update reserves
            uint256 tickInput = netInput.mulDiv(proportion, PRECISION);
            uint256 tickOutput = outputAmount.mulDiv(proportion, PRECISION);
            
            tick.reserves[inputIdx] += tickInput;
            tick.reserves[outputIdx] -= tickOutput;
            tick.feesAccrued[inputIdx] += feeAmount.mulDiv(proportion, PRECISION);
        }
        
        // Update total reserves
        _totalReserves[inputIdx] += inputAmount;
        _totalReserves[outputIdx] -= outputAmount;
    }
    
    /// @notice Flip tick between interior and boundary state
    function _flipTickState(uint256 tickId) internal {
        OrbitalTypes.OrbitalTick storage tick = ticks[tickId];
        
        if (tick.state == OrbitalTypes.TickState.INTERIOR) {
            // Move to boundary
            tick.state = OrbitalTypes.TickState.BOUNDARY;
            _removeFromArray(interiorTickIds, tickId);
            boundaryTickIds.push(tickId);
            delete isInteriorTick[tickId];
            isBoundaryTick[tickId] = true;
            
            emit BoundaryCrossed(tickId, OrbitalTypes.TickState.INTERIOR, OrbitalTypes.TickState.BOUNDARY);
        } else {
            // Move to interior
            tick.state = OrbitalTypes.TickState.INTERIOR;
            _removeFromArray(boundaryTickIds, tickId);
            interiorTickIds.push(tickId);
            delete isBoundaryTick[tickId];
            isInteriorTick[tickId] = true;
            
            emit BoundaryCrossed(tickId, OrbitalTypes.TickState.BOUNDARY, OrbitalTypes.TickState.INTERIOR);
        }
    }
    
    /// @notice Get total active liquidity
    function _getActiveLiquidity() internal view returns (uint256 total) {
        for (uint256 i = 0; i < activeTickIds.length; i++) {
            total += ticks[activeTickIds[i]].liquidity;
        }
    }
    
    /// @notice Remove tick from all tracking arrays
    function _removeTickFromTracking(uint256 tickId) internal {
        // Remove from active ticks
        uint256 index = tickIdToIndex[tickId];
        uint256 lastIndex = activeTickIds.length - 1;
        if (index != lastIndex) {
            uint256 lastTickId = activeTickIds[lastIndex];
            activeTickIds[index] = lastTickId;
            tickIdToIndex[lastTickId] = index;
        }
        activeTickIds.pop();
        delete tickIdToIndex[tickId];
        
        // Remove from state arrays
        if (isInteriorTick[tickId]) {
            _removeFromArray(interiorTickIds, tickId);
            delete isInteriorTick[tickId];
        } else if (isBoundaryTick[tickId]) {
            _removeFromArray(boundaryTickIds, tickId);
            delete isBoundaryTick[tickId];
        }
    }
    
    /// @notice Remove element from array
    function _removeFromArray(uint256[] storage array, uint256 element) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }
    
    /// @notice Get pool statistics
    function getPoolStats() external view returns (OrbitalTypes.PoolStats memory) {
        return OrbitalTypes.PoolStats({
            tokenSymbols: tokenSymbols,
            totalTicks: activeTickIds.length,
            interiorTicks: interiorTickIds.length,
            boundaryTicks: boundaryTickIds.length,
            totalReserves: _totalReserves,
            totalLiquidity: totalLiquidity
        });
    }
    
    /// @notice Collect accrued fees for a tick
    function collectFees(uint256 tickId) external nonReentrant tickExists(tickId) {
        OrbitalTypes.OrbitalTick storage tick = ticks[tickId];
        require(tick.owner == msg.sender, "Not tick owner");
        
        uint256[] memory fees = tick.feesAccrued;
        tick.feesAccrued = new uint256[](tokenCount);
        
        for (uint256 i = 0; i < tokenCount; i++) {
            if (fees[i] > 0) {
                IERC20(tokens[i]).safeTransfer(msg.sender, fees[i]);
            }
        }
        
        emit FeesCollected(tickId, msg.sender, fees);
    }
    
    /// @notice Get total reserves (explicit getter to match interface)
    function totalReserves() external view override returns (uint256[] memory) {
        return _totalReserves;
    }
}