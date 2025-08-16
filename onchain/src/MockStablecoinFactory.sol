// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockToken.sol";

contract MockStablecoinFactory {
    MockToken public USDC;   // 6 decimals
    MockToken public USDT0;  // 6 decimals (per your symbol)
    MockToken public PYUSD;  // 6 decimals
    MockToken public USDe;   // 18 decimals

    event TokensCreated(address usdc, address usdt0, address pyusd, address usde);

    constructor(address owner_) {
        // Create tokens with zero initial supply; script will mint/distribute
        USDC  = new MockToken("USD Coin", "USDC", 6, 0, owner_);
        USDT0 = new MockToken("Tether USD (mock)", "USDT0", 6, 0, owner_);
        PYUSD = new MockToken("PayPal USD (mock)", "PYUSD", 6, 0, owner_);
        USDe  = new MockToken("USDe (mock)", "USDe", 18, 0, owner_);
        emit TokensCreated(address(USDC), address(USDT0), address(PYUSD), address(USDe));
    }
}
