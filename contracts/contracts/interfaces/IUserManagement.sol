// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IUserManagement {
    function registerUser(address user) external;
    function getUserBalance(address user) external view returns (uint256);
    function setUserBalance(address user, uint256 amount) external;
    function getUserProfile(address user) external view returns (string memory name, string memory email);
    function updateUserProfile(address user, string memory name, string memory email) external;
}
