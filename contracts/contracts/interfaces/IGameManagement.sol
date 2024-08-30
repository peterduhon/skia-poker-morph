// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameManagement {
    // Events
    event GameRoomCreated(uint256 indexed gameId, address indexed creator, uint256 buyInAmount, uint256 maxPlayers);
    event GameRoomStatusUpdated(uint256 indexed gameId, GameStatus newStatus);

    // Game Status Enum
    enum GameStatus { Waiting, Active, Completed }

    // Game Management
    function createGameRoom(uint256 buyInAmount, uint256 maxPlayers) external;
    function updateGameStatus(uint256 gameId, GameStatus status) external;
    function getGameRoom(uint256 gameId) external view returns (GameRoom memory);
    function getUserGames(address user) external view returns (uint256[] memory);

    // Structs
    struct GameRoom {
        uint256 id;
        address creator;
        uint256 buyInAmount;
        uint256 maxPlayers;
        uint256 createdAt;
        GameStatus status;
    }
}
