// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBettingAndPotManagement {
    // Events
    event BetPlaced(address indexed player, uint256 amount);
    event PotDistributed(address indexed winner, uint256 amount);

    // Betting and Pot Management
    function collectBuyIns() external;
    function resetRound() external;
    function endCurrentRound() external;
    function advancePhase() external;
    function resetBettingRound() external;
    function determineWinners() external;
    function determineWinnersForSidePot() external;
    function distributePots() external;
}
