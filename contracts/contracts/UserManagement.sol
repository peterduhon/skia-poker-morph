// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManagement {
    struct User {
        address userAddress;
        string username;
        uint256 balance;
    }

    mapping(address => User) public users;

    event UserRegistered(address indexed user, string username);
    event BalanceUpdated(address indexed user, uint256 newBalance);

    function registerUser(string calldata _username) external payable {
        require(bytes(users[msg.sender].username).length == 0, "User already registered");
        require(msg.value > 0, "Initial balance must be greater than 0");

        users[msg.sender] = User({
            userAddress: msg.sender,
            username: _username,
            balance: msg.value
        });

        emit UserRegistered(msg.sender, _username);
        emit BalanceUpdated(msg.sender, msg.value);
    }

    function updateBalance(address _user, uint256 _amount) external {
        // Add access control to restrict who can call this function (e.g., only game contracts)
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

    function getUserProfile(address _user) external view returns (string memory username, uint256 balance) {
        User memory user = users[_user];
        return (user.username, user.balance);
    }
}
