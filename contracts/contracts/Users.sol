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
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(!users[msg.sender].isRegistered, "User already registered");

        users[msg.sender].userAddress = msg.sender;
        users[msg.sender].username = _username;
        users[msg.sender].balance = msg.value;
        users[msg.sender].isRegistered = true;

        emit UserRegistered(msg.sender, _username);
        emit BalanceUpdated(msg.sender, msg.value);
    }

    function isUserRegistered(address _user) external view returns (bool) {
        return users[_user].isRegistered;
    }

    function getUsernameOrAddress(address _user) external view returns (string memory) {
        if (users[_user].isRegistered) {
            return users[_user].username;
        } else {
            return addressToString(_user);
        }
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function updateBalance(address _user, uint256 _amount) external onlyRole(GAME_CONTRACT_ROLE) {
        require(users[_user].balance + _amount >= users[_user].balance, "Overflow error");
        users[_user].balance += _amount;

        emit BalanceUpdated(_user, users[_user].balance);
    }

    function withdraw(uint256 _amount) external onlyOwner {
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
