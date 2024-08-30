// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract UserManagement is Ownable, AccessControl {
    bytes32 public constant GAME_CONTRACT_ROLE = keccak256("GAME_CONTRACT_ROLE");

    struct User {
        address userAddress;
        string username;
        uint256 balance;
    }

    mapping(address => User) public users;

    event UserRegistered(address indexed user, string username);
    event BalanceUpdated(address indexed user, uint256 newBalance);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Registers a new user with an initial balance.
     * @param _username The username of the user.
     */
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

    /**
     * @dev Updates the balance of a user (can only be called by authorized entities).
     * @param _user The address of the user.
     * @param _amount The amount to add or subtract from the user's balance.
     */
    function updateBalance(address _user, uint256 _amount) external onlyRole(GAME_CONTRACT_ROLE) {
        require(users[_user].balance + _amount >= users[_user].balance, "Overflow error");
        users[_user].balance += _amount;

        emit BalanceUpdated(_user, users[_user].balance);
    }

    /**
     * @dev Withdraws funds from the caller's account.
     * @param _amount The amount to withdraw.
     */
    function withdraw(uint256 _amount) external {
        require(users[msg.sender].balance >= _amount, "Insufficient balance");
        users[msg.sender].balance -= _amount;
        payable(msg.sender).transfer(_amount);

        emit BalanceUpdated(msg.sender, users[msg.sender].balance);
    }

    /**
     * @dev Retrieves the profile of a user.
     * @param _user The address of the user.
     * @return username The username of the user.
     * @return balance The balance of the user.
     */
    function getUserProfile(address _user) external view returns (string memory username, uint256 balance) {
        User memory user = users[_user];
        return (user.username, user.balance);
    }

    /**
     * @dev Grants GAME_CONTRACT_ROLE to an address.
     * @param account The address to grant the role to.
     */
    function grantGameContractRole(address account) public onlyOwner {
        grantRole(GAME_CONTRACT_ROLE, account);
    }
}
