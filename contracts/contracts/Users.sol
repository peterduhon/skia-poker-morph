// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Common.sol";

contract UserManagement is Ownable, AccessControl {
    bytes32 public constant GAME_CONTRACT_ROLE = keccak256("GAME_CONTRACT_ROLE");

    mapping(address => User) public users;

    event UserRegistered(address indexed user, string username);
    event BalanceUpdated(address indexed user, uint256 newBalance);

    constructor() {
        _setupRole(GAME_CONTRACT_ROLE, msg.sender);
    }

    function registerUser(string calldata _username) external payable {
        // require(bytes(users[msg.sender].username).length == 0, "User already registered");
        require(msg.value > 0, "Initial balance must be greater than 0");

        users[msg.sender] = User({
            userAddress: msg.sender,
            username: _username,
            balance: msg.value
        });

        emit UserRegistered(msg.sender, _username);
        emit BalanceUpdated(msg.sender, msg.value);
    }

    function updateBalance(address _user, uint256 _amount) external onlyRole(GAME_CONTRACT_ROLE) {
        require(users[_user].balance + _amount >= users[_user].balance, "Overflow error");
        users[_user].balance += _amount;

        emit BalanceUpdated(_user, users[_user].balance);
    }

    function withdraw(uint256 _amount) external {
        require(users[msg.sender].balance >= _amount, "Insufficient balance");
        users[msg.sender].balance -= _amount;
        payable(msg.sender).transfer(_amount);

        emit BalanceUpdated(msg.sender, users[msg.sender].balance);
    }

    function getUserNickName(address _user) external view returns (string memory) {
        return users[_user].username;
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return users[_user].balance;
    }

    function grantGameContractRole(address account) public onlyOwner {
        grantRole(GAME_CONTRACT_ROLE, account);
    }
}
