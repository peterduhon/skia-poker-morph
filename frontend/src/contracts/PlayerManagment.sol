// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PlayerManagement {
    // State variables
    struct Player {
        address playerAddress;
        uint256 balance;
        bool isRegistered;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    // Events
    event PlayerRegistered(address indexed playerAddress);
    event BalanceUpdated(address indexed playerAddress, uint256 newBalance);
    event PayoutProcessed(address indexed playerAddress, uint256 payoutAmount);

    // Modifier to check if the player is registered
    modifier onlyRegistered() {
        require(players[msg.sender].isRegistered, "Player is not registered.");
        _;
    }

    // Function to register a player
    function registerPlayer() public {
        require(!players[msg.sender].isRegistered, "Player is already registered.");
        
        players[msg.sender] = Player({
            playerAddress: msg.sender,
            balance: 0,
            isRegistered: true
        });

        playerAddresses.push(msg.sender);
        
        emit PlayerRegistered(msg.sender);
    }

    // Function to update player balance
    function updateBalance(address _playerAddress, uint256 _amount) internal onlyRegistered {
        require(players[_playerAddress].isRegistered, "Player is not registered.");

        players[_playerAddress].balance += _amount;
        
        emit BalanceUpdated(_playerAddress, players[_playerAddress].balance);
    }

    // Function to process payouts
    function processPayout(address _playerAddress, uint256 _amount) internal onlyRegistered {
        require(players[_playerAddress].balance >= _amount, "Insufficient balance.");

        players[_playerAddress].balance -= _amount;
        payable(_playerAddress).transfer(_amount);

        emit PayoutProcessed(_playerAddress, _amount);
    }

    // Function to get player balance
    function getPlayerBalance(address _playerAddress) public view returns (uint256) {
        return players[_playerAddress].balance;
    }

    // Function to get the total number of registered players
    function getTotalPlayers() public view returns (uint256) {
        return playerAddresses.length;
    }

    // Fallback function to accept ETH deposits
    receive() external payable {}

    // Function to withdraw contract balance (for admin only, if applicable)
    function withdrawContractBalance() external {
        // Add admin check if necessary
        payable(msg.sender).transfer(address(this).balance);
    }
}
