// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeLT.sol";

/// @title Quadratic Funding Contract
/// @dev This contract allows users to participate in quadratic funding for projects.
contract QuadraticFunding is Ownable {

    uint256 public matchingPool; // Total amount available for matching
    uint256 public totalProjectsCount; // Total count of added projects
    uint256 public pendingWithdrawals; // Count of pending withdrawals
    uint256 private constant withdrawalDeadline = 7 days;
    uint256 public withdrawalStartTime; // Time that matching funds withdrawal gets enabled
    bool public withdrawalEnabled; // Flag to enable withdrawal of matching funds
    DeLT internal immutable delToken; // Reference to the DeLT token contract

    // Mapping of project IDs to projects
    mapping(uint256 => Project) public projects; // Mapping for project ID to project details

    // Events
    event MatchingFundWithdrawn(
        uint256 indexed projectId,
        address indexed creator
    );
    event MatchingPoolIncreased(
        uint256 indexed addedAmount,
        uint256 indexed currentAmount
    );

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
        delToken = DeLT(_delToken); // Initialize the DeLT token contract
    }

    /// @dev Function to withdraw funds from the contract's DeLT token balance.
    /// @param amount The amount of DeLT tokens to withdraw.
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        uint256 contractBalance = delToken.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient contract balance");

        // Update matchingPool before transferring tokens
        matchingPool -= amount;
        bool transferSuccess = delToken.transfer(owner(), amount);
        require(transferSuccess, "Token transfer failed");
    }

    // @dev Function to reset the contributions count of projects
    // It is useful to start a new quadratic funding round and ignore past contributions
    function resetContributions() external onlyOwner {
        require(!withdrawalEnabled, "Whithdrawal is enabled");
        uint256 projectsCount = totalProjectsCount;
        for (uint256 i = 0; i < projectsCount; i++) {
                projects[i].contributionsCount = 0;
        } 
    }

    /// @dev Increase the matching pool with DeLT tokens.
    /// @param amountToPool The amount of DeLT tokens to add to the matching pool.
    function increaseMatchingPool(uint256 amountToPool) public {
        require(amountToPool > 0, "Amount to pool must be greater than 0");
        
        // Avoid reentrancy
        // Transfer tokens before updating matching pool to avoid potential reentrancy issues
        bool transferSuccess = delToken.transferFrom(msg.sender, address(this), amountToPool);
        require(transferSuccess, "Token transfer failed");
       
        matchingPool += amountToPool;
        emit MatchingPoolIncreased(amountToPool, matchingPool);
    }

    // Based on the quadratic funding:
    // The portion of each project is power 2 of the sum of squer roots of its contributions
    // Each contribution amount for a project is a constant value (projects[i].contributionsAmount)
    // The contributions count for a project (means donations) is stored in projects[i].contributionsCount
    // So the portion of a project will be = (sqrt(contributionsAmount) + ... + sqrt(contributionsAmount))^2 = (contributionsCount * sqrt(contributionsAmount))^2
    // The denominator is the sum of the portion of all projects
    // The matching fund for each project is = its portion * total fund in matching pool / denominator

    /// @dev Update the matching funds for each project.
    /// @return A boolean indicating whether the update was successful.
    function updateMatchingFunds() public onlyOwner returns (bool) {
        uint256 totalFund = matchingPool;
        // It prevents to update matching funds if some of the projects have not withdraw their funds yet
        require(pendingWithdrawals == 0, "Pending withdrawals exist");
        require(totalFund > 0, "Matching pool is empty");

        uint256 projectsCount = totalProjectsCount;
        uint256[] memory portion = new uint256[](projectsCount);
        uint256 denominator;
        (portion, denominator) = calculatePortions();
        uint256 pendings;

        // Assign matching funds to projects
        for (uint256 i = 0; i < projectsCount; i++) {
            uint256 matchingFund = portion[i] * totalFund / denominator;
            if (matchingFund > 0) {
                projects[i].matchingFund = matchingFund;
                pendings++;
            }
        }
        // Update pending withdrawals
        pendingWithdrawals = pendings;
        return true;
    }

    /// @dev Toggle the withdrawal of matching funds.
    function toggleWithdrawFunds() public onlyOwner {
    if (withdrawalEnabled) {
        require(pendingWithdrawals == 0 || 
            block.timestamp - withdrawalStartTime > withdrawalDeadline, 
            "Pending withdrawals exist"
        );
        withdrawalEnabled = false;
        withdrawalStartTime = 0;
        pendingWithdrawals = 0;
    } else {
        require(totalProjectsCount > 0, "No projects added");
        require(matchingPool > 0, "Matching pool is empty");

        // Update the matching funds if they are not up to date
        // If the matching pool is not empty and the projects counts is more than 0, 
        // but the pending withdrawals is 0 means the matching funds is not up to date
        if (pendingWithdrawals == 0) {
            require(updateMatchingFunds(), "Update matching funds failed");
        }
        withdrawalEnabled = true;
        withdrawalStartTime = block.timestamp;
    }
    }

    /// @dev Withdraw matching funds for a specific project.
    /// @param projectId The ID of the project for which funds are being withdrawn.
    function withdrawMatchingFund(uint256 projectId) public {
        require(withdrawalEnabled, "Withdraw is not enabled");
        require(
            block.timestamp - withdrawalStartTime < withdrawalDeadline,
            "Withdrawal time has been finished"
        );
        Project memory project = projects[projectId];
        require(project.owner == msg.sender, "Only project owner can withdraw");
        
        require(project.matchingFund > 0, "No matching amount");
        
        // Avoid reentrancy
        // Update the matching fund to 0 before transfering tokens to avoid potential reentrancy issues
        projects[projectId].matchingFund = 0;

        // Ensure that the withdrawal is processed
        bool transferSuccess = delToken.transfer(msg.sender, project.matchingFund);
        require(transferSuccess, "Token transfer failed");
        
        // Update matching pool and pending withdrawals
        matchingPool -= project.matchingFund;
        pendingWithdrawals--;

        emit MatchingFundWithdrawn(projectId, msg.sender);
    }

    function getDeLTAddress() public view returns (address) {
        return address(delToken);
    }

    /// @dev Add a project to the matching projects.
    /// @param projectId The ID of the project to be added.
    /// @param contributionAmount The amount for per contribution for the project.
    function addToMatchingProjects(
        uint256 projectId,
        uint256 contributionAmount
    ) internal {
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

    /// @dev Calculate portions (shares) for each project.
    /// @return An array of portions indicating each project's share.
    function calculatePortions() internal view returns (uint256[] memory, uint256) {

        uint256 projectsCount = totalProjectsCount;
        uint256[] memory portion = new uint256[](projectsCount);
        uint256 denominator;
        for (uint256 i = 0; i < projectsCount; i++) {
            uint256 contributions = projects[i].contributionsCount;
            if (contributions > 0) {
                uint256 amount = projects[i].contributionsAmount;
                uint256 sumOfSquareRoots = contributions * sqrt(amount);
                portion[i] = sumOfSquareRoots * sumOfSquareRoots;
                denominator += portion[i];
            }
        }
        require(denominator > 0, "No portions found");
        return (portion, denominator);
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
