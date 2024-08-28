// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IGameManagement {
    enum RoomStatus { Created, Active, Finished }

    function createRoom(uint256 buyIn) external returns (uint256 roomId);
    function getRoomStatus(uint256 roomId) external view returns (RoomStatus);
    function getRoomBuyIn(uint256 roomId) external view returns (uint256);
    function setRoomStatus(uint256 roomId, RoomStatus status) external;
}
