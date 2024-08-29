// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GameManagement is Ownable {
    enum GameStatus { Waiting, Active, Completed }
    
    struct GameRoom {
        uint256 id;
        address creator;
        uint256 buyInAmount;
        uint256 maxPlayers;
        uint256 createdAt;
        GameStatus status;
    }
    
    uint256 public nextGameId;
    mapping(uint256 => GameRoom) public gameRooms;
    mapping(address => uint256[]) public userGames; // Track games by user address

    event GameRoomCreated(uint256 indexed gameId, address indexed creator, uint256 buyInAmount, uint256 maxPlayers);
    event GameRoomStatusUpdated(uint256 indexed gameId, GameStatus newStatus);

    constructor() {
        nextGameId = 0;
    }
    
    function createGameRoom(uint256 _buyInAmount, uint256 _maxPlayers) external onlyOwner {
        require(_buyInAmount > 0, "Buy-in amount must be greater than 0");
        require(_maxPlayers > 1, "Number of players must be greater than 1");

        uint256 gameId = nextGameId++;
        GameRoom memory newRoom = GameRoom({
            id: gameId,
            creator: msg.sender,
            buyInAmount: _buyInAmount,
            maxPlayers: _maxPlayers,
            createdAt: block.timestamp,
            status: GameStatus.Waiting
        });

        gameRooms[gameId] = newRoom;
        userGames[msg.sender].push(gameId);

        emit GameRoomCreated(gameId, msg.sender, _buyInAmount, _maxPlayers);
    }

    function updateGameStatus(uint256 _gameId, GameStatus _status) external onlyOwner {
        require(gameRooms[_gameId].id == _gameId, "Game room does not exist");
        gameRooms[_gameId].status = _status;

        emit GameRoomStatusUpdated(_gameId, _status);
    }

    function getGameRoom(uint256 _gameId) external view returns (GameRoom memory) {
        require(gameRooms[_gameId].id == _gameId, "Game room does not exist");
        return gameRooms[_gameId];
    }

    function getUserGames(address _user) external view returns (uint256[] memory) {
        return userGames[_user];
    }
}
