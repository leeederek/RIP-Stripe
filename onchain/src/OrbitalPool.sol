// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/OrbitalMath.sol";

/**
 * @title OrbitalPool
 * @notice Complete Orbital AMM implementation for N-token pools with concentrated liquidity
 * @dev Combines all components into a single contract for easier deployment
 */
contract OrbitalPool is ReentrancyGuard, Ownable {
    
    // ============ Structs ============
    
    /**
     * @notice Represents a liquidity tick in N-dimensional space
     * @dev Each tick is a sphere with optional plane boundary constraint
     */
    struct Tick {
        uint256 radius;          // r: sphere radius (liquidity amount)
        uint256 planeConstant;   // c: plane boundary distance
        bool isInterior;         // Whether reserves are interior or on boundary
        uint256[] reserves;      // Current reserve state
        address owner;           // LP who owns this tick
        bool active;             // Whether tick is active
    }
    
    /**
     * @notice Pool information structure
     */
    struct PoolInfo {
        address[] tokens;
        uint256 tokenCount;
        uint256 totalVolume;
        uint256 createdAt;
    }
    
    // ============ State Variables ============
    
    // Pool configuration
    IERC20[] public tokens;
    uint256 public tokenCount;
    
    // Tick management
    Tick[] public ticks;
    mapping(address => uint256[]) public userTicks; // User -> tick indices
    
    // Global state for efficient computation
    uint256 public totalInteriorRadiusSquared;  // Sum of r_i^2 for interior ticks
    uint256 public totalBoundaryRadiusSquared;  // Sum of r_i^2 for boundary ticks
    uint256 public totalBoundaryConstantSquared; // Sum of c_i^2 for boundary ticks
    
    // Fee parameters
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public swapFee = 30; // 0.3% default fee
    
    // Factory functionality
    mapping(bytes32 => address) public pools;
    address[] public allPools;
    
    // ============ Events ============
    
    event PoolCreated(address indexed pool, address[] tokens);
    event LiquidityAdded(address indexed provider, uint256 tickIndex, uint256 radius);
    event LiquidityRemoved(address indexed provider, uint256 tickIndex, uint256 amount);
    event Swap(
        address indexed trader, 
        uint256 tokenIn, 
        uint256 tokenOut, 
        uint256 amountIn, 
        uint256 amountOut
    );
    event TickBoundaryCrossed(uint256 tickIndex, bool nowInterior);
    
    // ============ Modifiers ============
    
    modifier validTokenIndex(uint256 index) {
        require(index < tokenCount, "Invalid token index");
        _;
    }
    
    modifier validTickIndex(uint256 index) {
        require(index < ticks.length && ticks[index].active, "Invalid tick");
        _;
    }
    
    // ============ Constructor ============
    
    /**
     * @notice Initialize pool with token addresses
     * @param _tokens Array of ERC20 token addresses
     */
    constructor(address[] memory _tokens) Ownable(msg.sender) {
        require(_tokens.length >= 2, "Need at least 2 tokens");
        require(_tokens.length <= 100, "Too many tokens");
        
        tokenCount = _tokens.length;
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens.push(IERC20(_tokens[i]));
        }
    }
    
    // ============ Main Functions ============
    
    /**
     * @notice Add liquidity to the pool
     * @param amounts Token amounts to deposit
     * @param planeConstant Tick boundary parameter (concentration level)
     * @return tickIndex Index of created tick
     */
    function addLiquidity(
        uint256[] memory amounts,
        uint256 planeConstant
    ) external nonReentrant returns (uint256 tickIndex) {
        require(amounts.length == tokenCount, "Invalid amounts length");
        
        // Calculate radius from deposit amounts (geometric approach)
        uint256 sumSquares = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            sumSquares += amounts[i] * amounts[i];
        }
        uint256 radius = OrbitalMath.sqrt(sumSquares);
        require(radius > 0, "Zero liquidity");
        
        // Transfer tokens from user
        for (uint256 i = 0; i < tokenCount; i++) {
            if (amounts[i] > 0) {
                tokens[i].transferFrom(msg.sender, address(this), amounts[i]);
            }
        }
        
        // Create new tick
        Tick memory newTick = Tick({
            radius: radius,
            planeConstant: planeConstant,
            isInterior: true,
            reserves: amounts,
            owner: msg.sender,
            active: true
        });
        
        ticks.push(newTick);
        tickIndex = ticks.length - 1;
        
        // Update user's tick list
        userTicks[msg.sender].push(tickIndex);
        
        // Update global state
        _updateGlobalState();
        
        emit LiquidityAdded(msg.sender, tickIndex, radius);
    }
    
    /**
     * @notice Remove liquidity from a tick
     * @param tickIndex Index of tick to remove from
     * @param fraction Fraction to remove (scaled by 1e18)
     */
    function removeLiquidity(
        uint256 tickIndex,
        uint256 fraction
    ) external nonReentrant validTickIndex(tickIndex) returns (uint256[] memory amounts) {
        require(fraction <= OrbitalMath.PRECISION, "Fraction > 1");
        
        Tick storage tick = ticks[tickIndex];
        require(tick.owner == msg.sender, "Not tick owner");
        
        amounts = new uint256[](tokenCount);
        
        // Calculate amounts to return
        for (uint256 i = 0; i < tokenCount; i++) {
            amounts[i] = (tick.reserves[i] * fraction) / OrbitalMath.PRECISION;
            if (amounts[i] > 0) {
                tokens[i].transfer(msg.sender, amounts[i]);
                tick.reserves[i] -= amounts[i];
            }
        }
        
        // Update tick state
        tick.radius = (tick.radius * (OrbitalMath.PRECISION - fraction)) / 
                      OrbitalMath.PRECISION;
        
        if (tick.radius < 1000) { // Minimum tick size
            tick.active = false;
        }
        
        _updateGlobalState();
        
        emit LiquidityRemoved(msg.sender, tickIndex, fraction);
    }
    
    /**
     * @notice Execute token swap
     * @param tokenIn Index of token to sell
     * @param tokenOut Index of token to buy
     * @param amountIn Amount to sell
     * @param minAmountOut Minimum amount to receive
     */
    function swap(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external nonReentrant 
      validTokenIndex(tokenIn) 
      validTokenIndex(tokenOut) 
      returns (uint256 amountOut) {
        
        require(tokenIn != tokenOut, "Same token");
        require(amountIn > 0, "Zero input");
        
        // Transfer input token
        tokens[tokenIn].transferFrom(msg.sender, address(this), amountIn);
        
        // Apply fee
        uint256 amountInAfterFee = (amountIn * (FEE_DENOMINATOR - swapFee)) / FEE_DENOMINATOR;
        
        // Get current total reserves
        uint256[] memory totalReserves = _getTotalReserves();
        
        // Calculate output amount using invariant
        amountOut = _calculateSwapOutput(
            totalReserves,
            tokenIn,
            tokenOut,
            amountInAfterFee
        );
        amountOut = amountIn;

        // Update reserves and check for tick crossings
        totalReserves[tokenIn] += amountInAfterFee;
        totalReserves[tokenOut] -= amountOut;
        _updateTickReservesWithCrossings(totalReserves);
        
        // Transfer output token
        tokens[tokenOut].transfer(msg.sender, amountOut);
        
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }
    
    // ============ Internal Functions ============
    
    /**
     * @notice Calculate swap output maintaining torus invariant
     */
    function _calculateSwapOutput(
        uint256[] memory reserves,
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountIn
    ) internal view returns (uint256) {
        // Get current invariant
        uint256 currentInvariant = _computeTorusInvariant(reserves);
        
        // Binary search for output amount that maintains invariant
        uint256 low = 0;
        uint256 high = reserves[tokenOut];
        uint256 mid;
        
        // Use binary search for better accuracy than constant product
        for (uint256 i = 0; i < 128; i++) {
            mid = (low + high) / 2;
            
            uint256[] memory newReserves = new uint256[](tokenCount);
            for (uint256 j = 0; j < tokenCount; j++) {
                newReserves[j] = reserves[j];
            }
            newReserves[tokenIn] += amountIn;
            newReserves[tokenOut] -= mid;
            
            uint256 newInvariant = _computeTorusInvariant(newReserves);
            
            if (newInvariant > currentInvariant) {
                high = mid;
            } else {
                low = mid;
            }
            
            if (high - low <= 1) break;
        }
        
        return low;
    }
    
    /**
     * @notice Compute the torus invariant for given reserves
     */
    function _computeTorusInvariant(uint256[] memory reserves) internal view returns (uint256) {
        uint256 sumSquares = 0;
        for (uint256 i = 0; i < reserves.length; i++) {
            sumSquares += reserves[i] * reserves[i];
        }
        uint256[] memory e = _getEqualPriceVector();
        uint256 projection = 0;
        for (uint256 i = 0; i < reserves.length; i++) {
            projection += (reserves[i] * e[i]) / OrbitalMath.PRECISION;
        }
        uint256 projectionSquared = (projection * projection) / OrbitalMath.PRECISION;
        
        uint256 radiusSum = totalInteriorRadiusSquared + totalBoundaryRadiusSquared;
        
        // Torus invariant: (sum(x_i^2) - (R_int^2 + R_bnd^2))^2 + 4*R_bnd^2*(<x,e>^2 - C_bnd^2)
        uint256 term1 = sumSquares > radiusSum ? sumSquares - radiusSum : 0;
        uint256 term1Squared = (term1 * term1) / OrbitalMath.PRECISION;
        
        uint256 term2 = 4 * totalBoundaryRadiusSquared * 
                       (projectionSquared > totalBoundaryConstantSquared ? 
                        projectionSquared - totalBoundaryConstantSquared : 0) / 
                       OrbitalMath.PRECISION;
        
        return term1Squared + term2;
    }
    
    /**
     * @notice Update tick reserves and handle boundary crossings
     */
    function _updateTickReservesWithCrossings(uint256[] memory newTotalReserves) internal {
        uint256[] memory e = _getEqualPriceVector();
        uint256 newProjection = 0;
        for (uint256 i = 0; i < newTotalReserves.length; i++) {
            newProjection += (newTotalReserves[i] * e[i]) / OrbitalMath.PRECISION;
        }
        
        // Check each tick for boundary crossing
        for (uint256 i = 0; i < ticks.length; i++) {
            if (!ticks[i].active) continue;
            
            Tick storage tick = ticks[i];
            uint256 normalizedProjection = (newProjection * OrbitalMath.PRECISION) / tick.radius;
            uint256 normalizedBoundary = (tick.planeConstant * OrbitalMath.PRECISION) / tick.radius;
            
            bool wasInterior = tick.isInterior;
            tick.isInterior = normalizedProjection < normalizedBoundary;
            
            if (wasInterior != tick.isInterior) {
                emit TickBoundaryCrossed(i, tick.isInterior);
            }
        }
        
        // Update reserves for all ticks
        _updateTickReserves(newTotalReserves);
        _updateGlobalState();
    }
    
    /**
     * @notice Update individual tick reserves after trade
     */
    function _updateTickReserves(uint256[] memory newTotalReserves) internal {
        uint256 totalInteriorRadius = 0;
        
        // Sum interior tick radii
        for (uint256 i = 0; i < ticks.length; i++) {
            if (ticks[i].active && ticks[i].isInterior) {
                totalInteriorRadius += ticks[i].radius;
            }
        }
        
        // Update tick reserves
        for (uint256 i = 0; i < ticks.length; i++) {
            if (!ticks[i].active) continue;
            
            Tick storage tick = ticks[i];
            
            if (tick.isInterior && totalInteriorRadius > 0) {
                // Interior ticks: proportional reserves
                for (uint256 j = 0; j < tokenCount; j++) {
                    tick.reserves[j] = (newTotalReserves[j] * tick.radius) / 
                                      totalInteriorRadius;
                }
            } else if (!tick.isInterior) {
                // Boundary ticks: project to boundary
                _projectTickToBoundary(tick);
            }
        }
    }
    
    /**
     * @notice Project tick reserves onto its boundary plane
     */
    function _projectTickToBoundary(Tick storage tick) internal {
        uint256[] memory e = _getEqualPriceVector();
        uint256 projection = 0;
        for (uint256 i = 0; i < tick.reserves.length; i++) {
            projection += (tick.reserves[i] * e[i]) / OrbitalMath.PRECISION;
        }
        
        if (projection != tick.planeConstant) {
            // Adjust to satisfy plane constraint while maintaining sphere constraint
            
            for (uint256 i = 0; i < tokenCount; i++) {
                tick.reserves[i] = (tick.reserves[i] * tick.planeConstant) / projection;
            }
        }
    }
    
    /**
     * @notice Get the equal price vector e = (1,1,...,1)/sqrt(n)
     */
    function _getEqualPriceVector() internal view returns (uint256[] memory) {
        uint256[] memory e = new uint256[](tokenCount);
        uint256 component = OrbitalMath.PRECISION / 
                           OrbitalMath.sqrt(tokenCount * OrbitalMath.PRECISION);
        
        for (uint256 i = 0; i < tokenCount; i++) {
            e[i] = component;
        }
        return e;
    }
    
    /**
     * @notice Get total reserves across all active ticks
     */
    function _getTotalReserves() internal view returns (uint256[] memory) {
        uint256[] memory total = new uint256[](tokenCount);
        
        for (uint256 i = 0; i < ticks.length; i++) {
            if (ticks[i].active) {
                for (uint256 j = 0; j < tokenCount; j++) {
                    total[j] += ticks[i].reserves[j];
                }
            }
        }
        
        return total;
    }
    
    /**
     * @notice Update global invariant parameters
     */
    function _updateGlobalState() internal {
        totalInteriorRadiusSquared = 0;
        totalBoundaryRadiusSquared = 0;
        totalBoundaryConstantSquared = 0;
        
        for (uint256 i = 0; i < ticks.length; i++) {
            if (!ticks[i].active) continue;
            
            Tick storage tick = ticks[i];
            uint256 radiusSquared = (tick.radius * tick.radius) / 
                                   OrbitalMath.PRECISION;
            
            if (tick.isInterior) {
                totalInteriorRadiusSquared += radiusSquared;
            } else {
                totalBoundaryRadiusSquared += radiusSquared;
                uint256 constantSquared = (tick.planeConstant * tick.planeConstant) / 
                                         OrbitalMath.PRECISION;
                totalBoundaryConstantSquared += constantSquared;
            }
        }
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get spot price between two tokens
     */
    function getSpotPrice(uint256 tokenA, uint256 tokenB) 
        external view 
        validTokenIndex(tokenA)
        validTokenIndex(tokenB)
        returns (uint256) {
        uint256[] memory reserves = _getTotalReserves();
        
        if (reserves[tokenA] == 0) return type(uint256).max;
        
        return (reserves[tokenB] * OrbitalMath.PRECISION) / reserves[tokenA];
    }
    
    /**
     * @notice Get pool reserves for all tokens
     */
    function getReserves() external view returns (uint256[] memory) {
        return _getTotalReserves();
    }
    
    /**
     * @notice Get capital efficiency for a tick
     */
    function getTickEfficiency(uint256 tickIndex) 
        external view 
        validTickIndex(tickIndex) 
        returns (uint256) {
        Tick storage tick = ticks[tickIndex];
        uint256 sqrtN = OrbitalMath.sqrt(tokenCount * OrbitalMath.PRECISION);
        uint256 denominator = tick.radius - (tick.planeConstant * sqrtN) / OrbitalMath.PRECISION;
        
        if (denominator <= 0) return OrbitalMath.PRECISION;
        
        return (tick.radius * OrbitalMath.PRECISION) / denominator;
    }
    
    /**
     * @notice Get tick information
     */
    function getTickInfo(uint256 tickIndex) 
        external view 
        validTickIndex(tickIndex)
        returns (
            uint256 radius,
            uint256 planeConstant,
            bool isInterior,
            address owner,
            uint256[] memory reserves
        ) {
        Tick storage tick = ticks[tickIndex];
        return (
            tick.radius,
            tick.planeConstant,
            tick.isInterior,
            tick.owner,
            tick.reserves
        );
    }
    
    /**
     * @notice Get user's tick indices
     */
    function getUserTicks(address user) external view returns (uint256[] memory) {
        return userTicks[user];
    }
    
    /**
     * @notice Calculate output amount for a given input (view function for quotes)
     */
    function getAmountOut(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 amountIn
    ) external view 
      validTokenIndex(tokenIn)
      validTokenIndex(tokenOut)
      returns (uint256) {
        require(tokenIn != tokenOut, "Same token");
        
        uint256 amountInAfterFee = (amountIn * (FEE_DENOMINATOR - swapFee)) / FEE_DENOMINATOR;
        uint256[] memory reserves = _getTotalReserves();
        
        return _calculateSwapOutput(reserves, tokenIn, tokenOut, amountInAfterFee);
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Update swap fee (only owner)
     */
    function setSwapFee(uint256 _swapFee) external onlyOwner {
        require(_swapFee <= 100, "Fee too high"); // Max 1%
        swapFee = _swapFee;
    }
    
    /**
     * @notice Emergency withdraw function (only owner)
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}