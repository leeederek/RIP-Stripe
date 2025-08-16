// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockToken is ERC20, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address initialHolder_
    ) ERC20(name_, symbol_) Ownable(initialHolder_) {
        _decimals = decimals_;
        if (initialSupply_ > 0) {
            _mint(initialHolder_, initialSupply_);
        }
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @notice owner (deployer) can mint extra test funds
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
