// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Common.sol";

contract AIPlayerManagement {
    function decideBettingAction(
        uint256 handStrength,
        uint256 potSize,
        uint256 position,
        uint256 currentBet,
        uint256 playerBalance,
        PlayerAction[] memory opponentHistory
    ) public view returns (PlayerAction, uint256) {
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 100;
        
        if (handStrength > 80 && randomFactor > 20) {
            if (playerBalance > currentBet * 3) {
                return (PlayerAction.Raise, currentBet * 2);
            } else {
                return (PlayerAction.Call, currentBet);
            }
        } else if (handStrength > 60 || randomFactor > 50) {
            if (currentBet == 0) {
                return (PlayerAction.Check, 0);
            } else {
                return (PlayerAction.Call, currentBet);
            }
        } else if (currentBet == 0 && randomFactor > 70) {
            return (PlayerAction.Bet, playerBalance / 10); // Small bet as a bluff
        } else if (playerBalance <= currentBet) {
            return (PlayerAction.AllIn, playerBalance);
        } else {
            return (PlayerAction.Fold, 0);
        }
    }
}