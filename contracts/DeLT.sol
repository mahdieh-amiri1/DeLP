// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DeLT Token Contract
/// @dev This contract represents the DeLT (DelToken) ERC20 token.
contract DeLT is ERC20, Ownable {
    uint256 public maxSupply;
    /// @dev Constructor to initialize the token with a name and symbol.
    constructor() ERC20("DelToken", "DeLT") {
        // Mint initial tokens to the contract creator.
        // Total Supply = 1 billion (1e9) and decimals = 18
        uint256 totalSupply = 1e9 * 1e18;
        maxSupply = totalSupply;
        uint256 initialSupply = totalSupply / 10; // 10% initial supply
        _mint(msg.sender, initialSupply);
    }

    /// @dev Function to mint additional tokens (only callable by the owner).
    /// @param to The address to which the tokens will be minted.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        uint256 totalSupply = maxSupply;
        require(totalSupply + amount <= totalSupply, "Exceeds max supply limit");
        _mint(to, amount);
    }

    /// @dev Function to burn tokens (only callable by the owner).
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
