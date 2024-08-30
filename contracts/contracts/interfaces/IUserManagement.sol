// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUserManagement {
    // Events
    event UserRegistered(address indexed user, string username);
    event BalanceUpdated(address indexed user, uint256 newBalance);

    // User Management
    function registerUser(string calldata username) external payable;
    function updateBalance(address user, uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getUserProfile(address user) external view returns (string memory username, uint256 balance);
}
