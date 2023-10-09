// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeLT is ERC20, Ownable {
    // Constructor to initialize the token with a name and symbol
    constructor() ERC20("DelToken", "DeLT") {
        // Mint initial tokens to the contract creator
        // Total Supply = 1 B and decimals = 18
        uint256 initialSupply = 1000000000 * 1000000000000;
        _mint(msg.sender, initialSupply);
    }

    // Function to mint additional tokens (only callable by the owner)
    // function mint(address to, uint256 amount) external onlyOwner {
    //     _mint(to, amount);
    // }

    // Function to burn tokens (only callable by the owner)
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
