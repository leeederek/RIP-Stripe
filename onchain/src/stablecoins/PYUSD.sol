pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PYUSD is ERC20 {
    constructor(uint256 initialMint_) ERC20("PYUSD", "PYUSD") {
        _mint(msg.sender, initialMint_);
    }
}
