// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeLT.sol";

/// @title Quadratic Funding Contract
/// @dev This contract allows users to participate in quadratic funding for projects.
contract QuadraticFunding is Ownable {

    DeLT internal _DeLT; // Reference to the DeLT token contract

    // Mapping for project ID to its count of contributions
    mapping (uint256 => uint256) public contributionsCount;

    // Mapping for project ID to the total contribution amount
    mapping (uint256 => uint256) public contributionsAmount;

    // Mapping for project ID to its owner address
    mapping (uint256 => address) public projectOwners;

    // Mapping for project ID to its matching fund
    mapping (uint256 => uint256) public projectMatchingFunds;

    uint256 public totalProjectsCount; // Total count of added projects
    bool public withdrawEnabled; // Flag to enable withdrawal of matching funds
    uint256 public matchingPool; // Total amount available for matching
    uint256 public pendingWithdraws; // Count of pending withdrawals

    event MatchingFundWithdrawn(uint256 indexed projectId, address indexed creator);
    event MatchingPoolIncreased(uint256 indexed addedAmount, uint256 indexed currentAmount);
    event FundsWithdrawn(uint256 indexed withdrawnAmount, uint256 currentAmount);

    /// @dev Constructor to initialize the contract with the DeLT token address.
    /// @param _delToken Address of the DeLT token contract.
    constructor(address _delToken) {
        _DeLT = DeLT(_delToken); // Initialize the DeLT token contract
    }

    /// @dev Increase the matching pool with DeLT tokens.
    /// @param amountToPool The amount of DeLT tokens to add to the matching pool.
    function increaseMatchingPool(uint256 amountToPool) public {
        require(amountToPool > 0, "Amount to pool must be greater than 0");
        require(_DeLT.transferFrom(msg.sender, address(this), amountToPool), "Token transfer failed");
        matchingPool += amountToPool;
        emit MatchingPoolIncreased(amountToPool, matchingPool);
    }

    /// @dev Add a project to the tracking system.
    /// @param projectId The ID of the project to be added.
    /// @param contributionAmount The total contribution amount for the project.
    function addToMatchingProjects(uint256 projectId, uint256 contributionAmount) internal {
        projectOwners[projectId] = msg.sender;
        contributionsAmount[projectId] = contributionAmount;
        totalProjectsCount++;
    }

    function addToContributions(uint256 projectId) internal {
        contributionsCount[projectId]++;
    }

    /// @dev Update the matching funds for each project.
    /// @return A boolean indicating whether the update was successful.
    function updateMatchingFunds() internal onlyOwner returns (bool) {
        uint256 projectsCount = totalProjectsCount;
        uint256[] memory powerTwoOfSumOfSquareRoots = new uint256[](projectsCount);
        uint256 totalPowerTwoOfSumOfSquareRoots;
        uint256 totalFund = matchingPool;

        for (uint256 i = 0; i < projectsCount; i++) {
            uint256 contributions = contributionsCount[i];
            if (contributions > 0) {
                uint256 amount = contributionsAmount[i];
                uint256 sumOfSquareRoots = contributions * sqrt(amount);
                powerTwoOfSumOfSquareRoots[i] = sumOfSquareRoots * sumOfSquareRoots;
                totalPowerTwoOfSumOfSquareRoots += powerTwoOfSumOfSquareRoots[i];
            }
        }

        require(totalPowerTwoOfSumOfSquareRoots > 0, "No contributors found");

        for (uint256 i = 0; i < projectsCount; i++) {
            uint256 contributions = contributionsCount[i];
            if (contributions > 0) {
                projectMatchingFunds[i] += powerTwoOfSumOfSquareRoots[i] * totalFund / totalPowerTwoOfSumOfSquareRoots;
                pendingWithdraws++;
            }
        }
        return true;
    }

    /// @dev Enable withdrawal of matching funds.
    function enableWithdrawFunds() public onlyOwner {
        require(!withdrawEnabled, "Withdraw is already enabled");
        require(totalProjectsCount > 0, "No projects added");
        require(matchingPool > 0, "Matching pool is empty");
        require(updateMatchingFunds(), "Matching funds calculation failed");
        withdrawEnabled = true;
    }

    /// @dev Withdraw matching funds for a specific project.
    /// @param projectId The ID of the project for which funds are being withdrawn.
    function withdrawMatchingFund(uint256 projectId) public {
        require(withdrawEnabled, "Withdraw is not enabled");
        uint256 matchingAmount = projectMatchingFunds[projectId];
        require(projectOwners[projectId] == msg.sender, "Only project owner can withdraw");
        require(matchingAmount > 0, "No matching amount");
        projectMatchingFunds[projectId] = 0;
        contributionsCount[projectId] = 0;
        require(_DeLT.transfer(msg.sender, matchingAmount), "Token transfer failed");
        matchingPool -= matchingAmount;
        pendingWithdraws--;
        if (pendingWithdraws == 0) {
            withdrawEnabled = false;
        }
        emit MatchingFundWithdrawn(projectId, msg.sender);
    }

    /// @dev Calculate the square root of a number.
    /// @param x The number for which the square root is calculated.
    /// @return The square root of the given number.
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /// @dev Function to withdraw funds from the contract's DeLT token balance.
    /// @param amount The amount of DeLT tokens to withdraw.
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= _DeLT.balanceOf(address(this)), "Insufficient balance");
        matchingPool -= amount;
        bool transferSuccess = _DeLT.transfer(owner(), amount);
        require(transferSuccess, "Token transfer failed");
        emit FundsWithdrawn(amount, matchingPool);
    }
}
