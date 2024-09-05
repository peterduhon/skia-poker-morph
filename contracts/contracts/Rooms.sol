// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Common.sol";

contract RoomManagement is Ownable {
    uint256 public nextGameId;
    mapping(uint256 => Room) public rooms;
    mapping(uint256 => GameRoom) public gameRooms;
    mapping(uint256 => bool) public roomUpdateStatus;

    event PlayerAdded(uint256 roomId, address player, string nickName, uint256 chips);
    event PlayerInfoUpdated(uint256 roomId, address player, string nickName, uint256 chips);
    event PlayerRemoved(uint256 roomId, address player);
    event GameRoomCreated(uint256 indexed gameId, address indexed creator, uint256 buyInAmount, uint256 maxPlayers);
    event GameRoomStatusUpdated(uint256 indexed gameId, GameStatus newStatus);
    
    function createGameRoom(string memory _title, uint256 _buyInAmount, uint256 _maxPlayers) external returns (uint256) {
        require(_buyInAmount > 0, "Poker Game : Buy-in amount must be greater than 0");
        require(_maxPlayers > 1, "Poker Game : Number of players must be greater than 1");
        require(bytes(_title).length > 0, "Poker Game: We need title to create room.");


        uint256 gameId = nextGameId++;
        gameRooms[gameId].id = gameId;
        gameRooms[gameId].title = _title;
        gameRooms[gameId].creator = msg.sender;
        gameRooms[gameId].buyInAmount = _buyInAmount;
        gameRooms[gameId].maxPlayers = _maxPlayers;
        gameRooms[gameId].createdAt = block.timestamp;
        gameRooms[gameId].status = GameStatus.Waiting;

        rooms[gameId].title = _title;
        rooms[gameId].id = gameId;
        rooms[gameId].buyInAmount = _buyInAmount;

        emit GameRoomCreated(gameId, msg.sender, _buyInAmount, _maxPlayers);
        return gameId;
    }

    function updateGameStatus(uint256 _gameId, GameStatus _status) external {
        require(gameRooms[_gameId].id == _gameId, "Poker Game : Game room does not exist.");
        require(msg.sender == rooms[_gameId].players[0], "Poker Game : Only creator can change game status.");
        gameRooms[_gameId].status = _status;

        emit GameRoomStatusUpdated(_gameId, _status);
    }

    function getGameInfo(uint256 _gameId) external view returns (GameRoom memory) {
        require(gameRooms[_gameId].id == _gameId, "Poker Game : Game room does not exist");
        return gameRooms[_gameId];
    }

    function getBuyInAmount(uint256 _gameID) external view returns(uint256) {
        return gameRooms[_gameID].buyInAmount;
    }
    
    function getMaxPlayers(uint256 _gameID) external view returns(uint256) {
        return gameRooms[_gameID].maxPlayers;
    }

    function addPlayer(uint256 roomId, address player, string memory nickName, uint256 chips) external {
        Room storage room = rooms[roomId];
        room.playerInfos[player] = PlayerInfo(nickName, chips);
        room.players.push(player);
        roomUpdateStatus[roomId] = true;

        emit PlayerAdded(roomId, player, nickName, chips);
    }

    function isUpdateAvailable(uint256 _roomID) external returns (bool) {
        bool res = roomUpdateStatus[_roomID];
        roomUpdateStatus[_roomID] = false;
        return res;
    }

    function getPlayerInfo(uint256 roomId, address player) external view returns (string memory nickName, uint256 chips) {
        Room storage room = rooms[roomId];
        PlayerInfo storage info = room.playerInfos[player];
        return (info.nickName, info.chips);
    }

    function updatePlayerInfo(uint256 roomId, address player, string memory nickName, uint256 chips) external onlyOwner {
        Room storage room = rooms[roomId];
        room.playerInfos[player] = PlayerInfo(nickName, chips);

        emit PlayerInfoUpdated(roomId, player, nickName, chips);
    }

    function removePlayer(uint256 roomId, address player) external onlyOwner {
        Room storage room = rooms[roomId];
        for (uint256 i = 0; i < room.players.length; i++) {
            if (room.players[i] == player) {
                room.players[i] = room.players[room.players.length - 1];
                room.players.pop();
                break;
            }
        }
        delete room.playerInfos[player];
        emit PlayerRemoved(roomId, player);
    }

    function getPlayers(uint256 roomId) external view returns (address[] memory) {
        return rooms[roomId].players;
    }
}
