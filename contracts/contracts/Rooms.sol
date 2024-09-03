// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RoomManagement is Ownable {
    struct Room {
        uint256 id;
        uint256 buyInAmount;
        mapping(address => PlayerInfo) playerInfos;
        address[] players;
    }

    struct PlayerInfo {
        string nickName;
        uint256 chips;
    }

    mapping(uint256 => Room) public rooms;

    event RoomCreated(uint256 roomId, uint256 buyInAmount);
    event PlayerAdded(uint256 roomId, address player, string nickName, uint256 chips);
    event PlayerInfoUpdated(uint256 roomId, address player, string nickName, uint256 chips);

    function createRoom(uint256 roomId, uint256 buyInAmount) external onlyOwner {
        Room storage room = rooms[roomId];
        room.id = roomId;
        room.buyInAmount = buyInAmount;

        emit RoomCreated(roomId, buyInAmount);
    }

    function getBuyInAmount(uint256 roomId) external view returns (uint256) {
        return rooms[roomId].buyInAmount;
    }

    function addPlayer(uint256 roomId, address player, string memory nickName, uint256 chips) external onlyOwner {
        Room storage room = rooms[roomId];
        room.playerInfos[player] = PlayerInfo(nickName, chips);
        room.players.push(player);

        emit PlayerAdded(roomId, player, nickName, chips);
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

    function getPlayers(uint256 roomId) external view returns (address[] memory) {
        return rooms[roomId].players;
    }
}
