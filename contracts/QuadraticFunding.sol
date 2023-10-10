// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeLT.sol";

/// @title Quadratic Funding Contract
/// @dev This contract allows users to participate in quadratic funding for projects.
contract QuadraticFunding is Ownable {

    uint256 public matchingPool;            // Total amount available for matching
    uint256 public totalProjectsCount;      // Total count of added projects
    DeLT private _DeLT;                     // Reference to the DeLT token contract
    bool private withdrawalEnabled;         // Flag to enable withdrawal of matching funds
    uint256 private pendingWithdrawals;     // Count of pending withdrawals
    uint256 private withdrawalStartTime;    // Time that matching funds withdrawal gets enabled
    uint256 constant private withdrawalDeadline = 7 days;
    
    // Mapping of project IDs to projects
    mapping (uint256 => Project) public projects; // Mapping for project ID to project details

    // Events
    event MatchingFundWithdrawn(uint256 indexed projectId, address indexed creator);
    event MatchingPoolIncreased(uint256 indexed addedAmount, uint256 indexed currentAmount);
    event FundsWithdrawn(uint256 indexed withdrawnAmount, uint256 currentAmount);

    // Structure to represent a project
    struct Project {
        uint256 contributionsCount;
        uint256 contributionsAmount;
        address owner;
        uint256 matchingFund;
        // bool withdrawalPending;
    }
    
    /// @dev Constructor to initialize the contract with the DeLT token address.
    /// @param _delToken Address of the DeLT token contract.
    constructor(address _delToken) {
        _DeLT = DeLT(_delToken); // Initialize the DeLT token contract
    }

    /// @dev Function to withdraw funds from the contract's DeLT token balance.
    /// @param amount The amount of DeLT tokens to withdraw.
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= _DeLT.balanceOf(address(this)), "Insufficient balance");
        matchingPool -= amount;
        require(_DeLT.transfer(owner(), amount), "Token transfer failed");
        emit FundsWithdrawn(amount, matchingPool);
    }

    /// @dev Increase the matching pool with DeLT tokens.
    /// @param amountToPool The amount of DeLT tokens to add to the matching pool.
    function increaseMatchingPool(uint256 amountToPool) public {
        require(amountToPool > 0, "Amount to pool must be greater than 0");
        require(_DeLT.transferFrom(msg.sender, address(this), amountToPool), "Token transfer failed");
        matchingPool += amountToPool;
        emit MatchingPoolIncreased(amountToPool, matchingPool);
    }

    /// @dev Remove a project from the matching projects.
    /// @param projectId The ID of the project to be added.
    function removeFromMatchingProject(uint256 projectId) public onlyOwner {
        require(projectId < totalProjectsCount, "Invalid project ID");
        delete projects[projectId];
        totalProjectsCount--;
    }

    /// @dev Update the matching funds for each project.
    /// @return A boolean indicating whether the update was successful.
    function updateMatchingFunds() public onlyOwner returns (bool) {
        uint256 projectsCount = totalProjectsCount;
        uint256[] memory powerTwoOfSumOfSquareRoots = new uint256[](projectsCount);
        uint256[] memory contributionsCount = new uint256[](projectsCount);
        uint256 totalPowerTwoOfSumOfSquareRoots;
        uint256 sumOfSquareRoots;
        uint256 contributions;
        uint256 amount;
        pendingWithdrawals = 0;
        uint256 totalFund = matchingPool;

        for (uint256 i = 0; i < projectsCount; i++){
            contributionsCount[i] = projects[i].contributionsCount;
        }
        for (uint8 i = 0; i < projectsCount; i++) {
            contributions = contributionsCount[i];
            if (contributions > 0) {
                amount = projects[i].contributionsAmount;
                sumOfSquareRoots = contributions * sqrt(amount);
                powerTwoOfSumOfSquareRoots[i] = sumOfSquareRoots * sumOfSquareRoots;
                totalPowerTwoOfSumOfSquareRoots += powerTwoOfSumOfSquareRoots[i];
            }
        }
        require(totalPowerTwoOfSumOfSquareRoots > 0, "No contributions found");
        for (uint8 i = 0; i < projectsCount; i++) {
            if (contributionsCount[i] > 0) {
                uint256 matchingFund = powerTwoOfSumOfSquareRoots[i] * totalFund / totalPowerTwoOfSumOfSquareRoots;
                projects[i].matchingFund = matchingFund;
                pendingWithdrawals++;
            }
        }
        return true;
    }

    /// @dev Enable withdrawal of matching funds.
    function enableWithdrawFunds() public onlyOwner {
        // withdrawalEnabled ? false : true; // Toggle
        require(!withdrawalEnabled, "Withdraw is already enabled");
        require(totalProjectsCount > 0, "No projects added");
        require(matchingPool > 0, "Matching pool is empty");

        // Update the matching funds if they are not up to date
        if (pendingWithdrawals == 0) {
            require(updateMatchingFunds(), "Update matching funds failed");
        }
        // require(updateMatchingFunds(), "Matching funds calculation failed");
        withdrawalEnabled = true;
        withdrawalStartTime = block.timestamp;
    }

    function disableWithdrawFunds() public onlyOwner {
        require(withdrawalEnabled, "Withdraw is already disabled");
        withdrawalEnabled = false;
        withdrawalStartTime = 0;
    }

    /// @dev Withdraw matching funds for a specific project.
    /// @param projectId The ID of the project for which funds are being withdrawn.
    function withdrawMatchingFund(uint256 projectId) public {
        require(withdrawalEnabled, "Withdraw is not enabled");
        require(block.timestamp - withdrawalStartTime < withdrawalDeadline, "Withdrawal time has been finished");
        uint256 matchingAmount = projects[projectId].matchingFund;
        require(projects[projectId].owner == msg.sender, "Only project owner can withdraw");
        require(matchingAmount > 0, "No matching amount");
        projects[projectId].matchingFund = 0;
        // projects[projectId].contributionsCount = 0;
        bool transferSuccess = _DeLT.transfer(msg.sender, matchingAmount);
        require(transferSuccess, "Token transfer failed");
        matchingPool -= matchingAmount;
        pendingWithdrawals--;
        if (pendingWithdrawals == 0) {
            withdrawalEnabled = false;
        }
        emit MatchingFundWithdrawn(projectId, msg.sender);
    }

    /// @dev Add a project to the matching projects.
    /// @param projectId The ID of the project to be added.
    /// @param contributionAmount The amount for per contribution for the project.
    function addToMatchingProjects(uint256 projectId, uint256 contributionAmount) internal {
        projects[projectId] = Project({
            contributionsCount: 0,
            contributionsAmount: contributionAmount,
            owner: msg.sender,
            matchingFund: 0
        });
        totalProjectsCount++;
    }

    /// @dev Add a contribution to a matching project.
    /// @param projectId The ID of the project to add a contribution.
    function addToContributions(uint256 projectId) internal {
        require(projectId < totalProjectsCount, "Invalid project ID");
        projects[projectId].contributionsCount++;
    }

    /// @dev Calculate the square root of a number.
    /// @param x The number for which the square root is calculated.
    /// @return The square root of the given number.
    function sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
