// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameMechanics {
    // Events
    event GameStarted();
    event GameEnded();

    // Game Mechanics
    function startGame() external;
    function endGame() external;
    function manageTurn(address player) external;
    function isRoundOver() external view returns (bool);
    function nextPlayerTurn() external;
    function placeBet(uint256 amount) external;
    function fold() external;
    function call() external;
    function raise(uint256 amount) external;
    function handleAllIn() external;
    function removePlayerFromActiveList(address player) external;
    function startNewRound() external;
}
