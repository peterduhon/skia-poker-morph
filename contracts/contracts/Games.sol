// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Common.sol";

contract GameManagement is Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
 
    uint256 public nextGameId;
    mapping(uint256 => GameRoom) public gameRooms;
    mapping(address => uint256[]) public userGames;

    event GameRoomCreated(uint256 indexed gameId, address indexed creator, uint256 buyInAmount, uint256 maxPlayers);
    event GameRoomStatusUpdated(uint256 indexed gameId, GameStatus newStatus);

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function createGameRoom(uint256 _buyInAmount, uint256 _maxPlayers) external onlyRole(ADMIN_ROLE) returns (uint256) {
        require(_buyInAmount > 0, "Buy-in amount must be greater than 0");
        require(_maxPlayers > 1, "Number of players must be greater than 1");

        uint256 gameId = nextGameId++;
        gameRooms[gameId].id = gameId;
        gameRooms[gameId].creator = msg.sender;
        gameRooms[gameId].buyInAmount = _buyInAmount;
        gameRooms[gameId].maxPlayers = _maxPlayers;
        gameRooms[gameId].createdAt = block.timestamp;
        gameRooms[gameId].status = GameStatus.Waiting;
    
        userGames[msg.sender].push(gameId);

        emit GameRoomCreated(gameId, msg.sender, _buyInAmount, _maxPlayers);
        return gameId;
    }

    function updateGameStatus(uint256 _gameId, GameStatus _status) external onlyRole(ADMIN_ROLE) {
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

    function grantAdminRole(address account) public onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    function getBuyInAmount(uint256 _gameID) external view returns(uint256) {
        return gameRooms[_gameID].buyInAmount;
    }
    
    function maxPlayers(uint256 _gameID) external view returns(uint256) {
        return gameRooms[_gameID].maxPlayers;
    }
}
