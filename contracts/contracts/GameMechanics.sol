// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CardManagement.sol";
import "./BettingAndPotManagement.sol";
import "./UserManagement.sol";

contract GameMechanics is Ownable {
    enum GamePhase { NotStarted, Registration, BuyIn, Playing, Ended }
    GamePhase public currentPhase;

    struct Card {
        uint8 rank;
        uint8 suit;
    }

    address public cardManagementAddress;
    address public bettingAndPotManagementAddress;
    address public userManagementAddress;

    modifier onlyDuringPhase(GamePhase phase) {
        require(currentPhase == phase, "Invalid game phase");
        _;
    }

    constructor(
        address _cardManagementAddress,
        address _bettingAndPotManagementAddress,
        address _userManagementAddress
    ) {
        cardManagementAddress = _cardManagementAddress;
        bettingAndPotManagementAddress = _bettingAndPotManagementAddress;
        userManagementAddress = _userManagementAddress;
    }

    /**
     * @dev Starts the game and transitions to the Registration phase.
     */
    function startGame() external onlyOwner onlyDuringPhase(GamePhase.NotStarted) {
        currentPhase = GamePhase.Registration;
    }

    /**
     * @dev Registers a player by interacting with the UserManagement contract.
     * @param player The address of the player to register.
     */
    function registerPlayer(address player) external onlyOwner onlyDuringPhase(GamePhase.Registration) {
        UserManagement userManagement = UserManagement(userManagementAddress);
        userManagement.registerPlayer(player);
    }

    /**
     * @dev Starts a new round of the game.
     */
    function startNewRound() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        CardManagement cardManagement = CardManagement(cardManagementAddress);
        cardManagement.initializeDeck();
        cardManagement.shuffleDeck();
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.resetRound();
    }

    /**
     * @dev Resets the current round.
     */
    function resetRound() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.resetRound();
    }

    /**
     * @dev Ends the current round.
     */
    function endCurrentRound() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.endCurrentRound();
    }

    /**
     * @dev Advances to the next phase of the game.
     */
    function advancePhase() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.advancePhase();
    }

    /**
     * @dev Manages the player's turn by processing their action.
     * @param player The address of the player.
     * @param action The action to perform (1: Bet, 2: Fold, 3: Call, 4: Raise, 5: All-in).
     * @param amount The amount involved in the action.
     */
    function manageTurn(address player, uint256 action, uint256 amount) external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        require(action >= 1 && action <= 5, "Invalid action");
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        if (action == 1) {
            bettingAndPotManagement.placeBet(player, amount);
        } else if (action == 2) {
            bettingAndPotManagement.fold(player);
        } else if (action == 3) {
            bettingAndPotManagement.call(player);
        } else if (action == 4) {
            bettingAndPotManagement.raise(player, amount);
        } else if (action == 5) {
            bettingAndPotManagement.handleAllIn(player, amount);
        }
    }

    /**
     * @dev Checks if the current round is over.
     * @return True if the round is over, false otherwise.
     */
    function isRoundOver() external view returns (bool) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        return bettingAndPotManagement.isRoundOver();
    }

    /**
     * @dev Moves to the next player's turn.
     */
    function nextPlayerTurn() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.nextPlayerTurn();
    }

    /**
     * @dev Removes a player from the active list.
     * @param player The address of the player to remove.
     */
    function removePlayerFromActiveList(address player) external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.removePlayerFromActiveList(player);
    }

    /**
     * @dev Ends the game and transitions to the Ended phase.
     */
    function endGame() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.determineWinners();
        bettingAndPotManagement.distributePots();
        currentPhase = GamePhase.Ended;
    }

    /**
     * @dev Resets the game to the NotStarted phase.
     */
    function resetGame() external onlyOwner onlyDuringPhase(GamePhase.Ended) {
        currentPhase = GamePhase.NotStarted;
    }

    /**
     * @dev Retrieves the list of winners.
     * @return Array of winner addresses.
     */
    function determineWinners() external view returns (address[] memory) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        return bettingAndPotManagement.determineWinners();
    }

    /**
     * @dev Retrieves the list of winners for side pots.
     * @return Array of winner addresses.
     */
    function determineWinnersForSidePot() external view returns (address[] memory) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        return bettingAndPotManagement.determineWinnersForSidePot();
    }

    /**
     * @dev Distributes pots at the end of the game.
     */
    function distributePots() external onlyOwner onlyDuringPhase(GamePhase.Ended) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.distributePots();
    }

    /**
     * @dev Resets the betting round.
     */
    function resetBettingRound() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        BettingAndPotManagement bettingAndPotManagement = BettingAndPotManagement(bettingAndPotManagementAddress);
        bettingAndPotManagement.resetBettingRound();
    }

    /**
     * @dev Evaluates a hand of cards.
     * @param hand The hand of cards to evaluate.
     * @return The strength of the hand.
     */
    function evaluateHand(Card[] memory hand) external view returns (uint256) {
        CardManagement cardManagement = CardManagement(cardManagementAddress);
        return cardManagement.evaluateHand(hand);
    }
}
