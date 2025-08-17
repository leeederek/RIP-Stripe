// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* ---------------------------- INTERFACES ---------------------------- */

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapPool {
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);
}

interface ICCTP {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);
}

/* ---------------------------- SOURCE CHAIN CONTRACT ---------------------------- */

contract SourceChainSwapAndBridge {
    address public immutable swapPool;
    address public immutable usdc;
    address public immutable pusd;
    address public immutable cctp;

    constructor(address _swapPool, address _usdc, address _pusd, address _cctp) {
        swapPool = _swapPool;
        usdc = _usdc;
        pusd = _pusd;
        cctp = _cctp;
    }

    /**
     * @notice User swaps PUSD -> USDC and then bridges via CCTP
     * @param amountIn Amount of PUSD user sends
     * @param minUSDC Minimum USDC acceptable after swap
     * @param destinationDomain Circle domain ID for destination chain (e.g., Base Sepolia)
     * @param mintRecipient Address on destination chain to receive USDC (converted to bytes32)
     */
    function swapAndBridge(
        uint256 amountIn,
        uint256 minUSDC,
        uint32 destinationDomain,
        bytes32 mintRecipient
    ) external {
        // Step 1: Transfer PUSD from user to this contract
        require(IERC20(pusd).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");

        // Step 2: Approve swap pool to spend PUSD
        IERC20(pusd).approve(swapPool, amountIn);

        // Step 3: Swap PUSD -> USDC
        uint256 usdcAmount = ISwapPool(swapPool).swap(pusd, usdc, amountIn, minUSDC);

        // Step 4: Approve CCTP contract to spend USDC
        IERC20(usdc).approve(cctp, usdcAmount);

        // Step 5: Call Circle's CCTP to burn USDC for cross-chain transfer
        ICCTP(cctp).depositForBurn(usdcAmount, destinationDomain, mintRecipient, usdc);
    }
}

/* ---------------------------- DESTINATION CHAIN CONTRACT ---------------------------- */

contract DestinationChainReceiver {
    address public immutable swapPool;
    address public immutable usdc;
    address public immutable pusd;

    constructor(address _swapPool, address _usdc, address _pusd) {
        swapPool = _swapPool;
        usdc = _usdc;
        pusd = _pusd;
    }

    /**
     * @notice Called after USDC is minted by CCTP. User can claim USDC or swap to PUSD.
     * @param amount Amount of USDC to swap (or leave if user wants USDC)
     * @param minPUSD Minimum PUSD after swap
     * @param user Recipient of final tokens
     * @param wantPUSD If true, swap to PUSD; if false, send USDC
     */
    function completeSwap(
        uint256 amount,
        uint256 minPUSD,
        address user,
        bool wantPUSD
    ) external {
        require(IERC20(usdc).balanceOf(address(this)) >= amount, "Not enough USDC");

        if (wantPUSD) {
            IERC20(usdc).approve(swapPool, amount);
            uint256 pusdAmount = ISwapPool(swapPool).swap(usdc, pusd, amount, minPUSD);
            IERC20(pusd).transfer(user, pusdAmount);
        } else {
            IERC20(usdc).transfer(user, amount);
        }
    }
}
