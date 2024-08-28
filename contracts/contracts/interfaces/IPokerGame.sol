// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IPokerGame {
    struct Card {
        uint8 suit;
        uint8 value;
    }

    function startGame(uint256 roomId) external;
    function placeBet(uint256 roomId, uint256 amount) external;
    function fold(uint256 roomId) external;
    function drawCard(uint256 roomId) external;
    function getPlayerHand(uint256 roomId, address player) external view returns (Card[] memory hand);
    function getGameStatus(uint256 roomId) external view returns (bool isActive, address[] memory players, uint256 currentPot);
    function endGame(uint256 roomId, address winner) external;
}
