// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Cards.sol";
import "./Rooms.sol";

/**
 * @title BettingAndPotManagement
 * @dev Manages the betting and pot distribution logic for a poker game.
 *      Handles player actions such as betting, folding, calling, raising, and going all-in.
 *      Integrates with CardManagement and RoomManagement contracts to manage game state.
 */
contract BettingAndPotManagement is Ownable, ReentrancyGuard {
    
    /**
     * @dev Enum representing the different phases of the poker game.
     * @param NotStarted The game has not started yet.
     * @param Registration Players are registering for the game.
     * @param BuyIn Players are placing their buy-ins.
     * @param Betting Players are currently betting.
     * @param Showdown The showdown phase where winners are determined.
     */
    enum Phase { NotStarted, Registration, BuyIn, Betting, Showdown }
    Phase public currentPhase;

    /// @notice Reference to the CardManagement contract.
    CardManagement public cardManagement;

    /// @notice Reference to the RoomManagement contract.
    RoomManagement public roomManagement;

    /// @notice Reference to the UserManagement contract.
    UserManagement public userManagement;

    /**
     * @dev Struct representing a player in the game.
     * @param chips The number of chips the player currently has.
     * @param isActive Indicates whether the player is active in the current round.
     * @param currentBet The amount the player has currently bet in the round.
     */
    struct Player {
        uint256 chips;
        bool isActive;
        uint256 currentBet;
    }

    /**
     * @dev Enum representing the suits of playing cards.
     */
    enum Suit { Spades, Hearts, Diamonds, Clubs }

    /**
     * @dev Enum representing the values of playing cards.
     */
    enum Value { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }

    /**
     * @dev Struct representing a playing card.
     * @param suit The suit of the card.
     * @param value The value of the card.
     */
    struct Card {
        Suit suit;
        Value value;
    }

    /// @notice Mapping from player addresses to their respective Player structs.
    mapping(address => Player) public players;

    /// @notice Array of addresses representing the currently active players in the round.
    address[] public activePlayers;

    /// @notice The total amount of chips in the pot for the current round.
    uint256 public totalPot;

    /// @notice The current highest bet in the betting round.
    uint256 public currentBet;

    /// @notice The ID of the room managing this game.
    uint256 public roomID;

    /**
     * @dev Modifier that restricts function execution to a specific game phase.
     * @param phase The required phase for the function to execute.
     *
     * Requirements:
     *
     * - The current game phase must match the specified `phase`.
     */
    modifier onlyDuringPhase(Phase phase) {
        require(currentPhase == phase, "Poker Game: Invalid phase");
        _;
    }

    // ========================================
    //                  EVENTS
    // ========================================

    /**
     * @dev Emitted when a player places a bet.
     * @param player The address of the player who placed the bet.
     * @param amount The amount of chips the player bet.
     */
    event BetPlaced(address indexed player, uint256 amount);

    /**
     * @dev Emitted when a player folds.
     * @param player The address of the player who folded.
     */
    event PlayerFolded(address indexed player);

    /**
     * @dev Emitted when a player calls a bet.
     * @param player The address of the player who called.
     * @param amount The amount of chips the player called.
     */
    event PlayerCalled(address indexed player, uint256 amount);

    /**
     * @dev Emitted when a player raises a bet.
     * @param player The address of the player who raised.
     * @param amount The new total bet amount after the raise.
     */
    event PlayerRaised(address indexed player, uint256 amount);

    /**
     * @dev Emitted when a player goes all-in.
     * @param player The address of the player who went all-in.
     * @param amount The amount of chips the player went all-in with.
     */
    event PlayerAllIn(address indexed player, uint256 amount);

    /**
     * @dev Emitted when a side pot is distributed.
     * @param sidePotIndex The index of the side pot.
     * @param winners The addresses of the winners sharing the side pot.
     * @param share The amount each winner receives from the side pot.
     */
    event SidePotDistributed(uint256 indexed sidePotIndex, address[] winners, uint256 share);

    /**
     * @dev Emitted when the main pot is distributed.
     * @param winners The addresses of the winners sharing the main pot.
     * @param share The amount each winner receives from the main pot.
     */
    event PotDistributed(address[] winners, uint256 share);

    // ========================================
    //                CONSTRUCTOR
    // ========================================

    /**
     * @notice Initializes the BettingAndPotManagement contract with necessary dependencies.
     * @dev Sets up references to CardManagement, RoomManagement, and UserManagement contracts.
     *      Initializes pot and bet values to zero.
     * @param _cardManagementAddress The address of the deployed CardManagement contract.
     * @param _roomManagementAddress The address of the deployed RoomManagement contract.
     * @param _userManagementAddress The address of the deployed UserManagement contract.
     * @param _roomID The ID of the room this contract will manage.
     */
    constructor(
        address _cardManagementAddress,
        address _roomManagementAddress,
        address _userManagementAddress,
        uint256 _roomID
    ) {
        cardManagement = CardManagement(_cardManagementAddress);
        roomManagement = RoomManagement(_roomManagementAddress);
        userManagement = UserManagement(_userManagementAddress);
        totalPot = 0;
        currentBet = 0;
        roomID = _roomID;
    }

    // ========================================
    //                FUNCTIONS
    // ========================================

    /**
     * @notice Collects buy-ins from all registered players and activates them for the game.
     * @dev Can only be called by the contract owner during the Registration phase.
     *      Retrieves the list of players and the buy-in amount from the RoomManagement contract.
     *      Initializes each player's chips and sets them as active.
     *      Transitions the game phase to BuyIn.
     */
    function collectBuyIns() external onlyOwner onlyDuringPhase(Phase.Registration) {
        address[] memory playersList = roomManagement.getAllPlayers(roomID);
        uint256 buyInAmount = roomManagement.getBuyInAmount();

        for (uint256 i = 0; i < playersList.length; i++) {
            address player = playersList[i];
            players[player].chips = buyInAmount;
            players[player].isActive = true;
            activePlayers.push(player);
        }
        currentPhase = Phase.BuyIn;
    }

    /**
     * @notice Resets the current betting round by clearing the pot and resetting player bets.
     * @dev Internal function used to prepare for a new betting round.
     *      Sets `totalPot` and `currentBet` to zero.
     *      Resets each active player's `currentBet` to zero.
     */
    function resetRound() internal {
        totalPot = 0;
        currentBet = 0;

        for (uint256 i = 0; i < activePlayers.length; i++) {
            address player = activePlayers[i];
            players[player].currentBet = 0;
        }
    }

    /**
     * @notice Ends the current betting round and transitions the game to the Showdown phase.
     * @dev Can only be called by the contract owner during the Betting phase.
     *      Ensures that all active players have matched the current highest bet.
     *      Reverts if any player has not matched the current bet.
     *      Transitions the game phase to Showdown upon successful validation.
     *
     * Requirements:
     *
     * - All active players must have their `currentBet` equal to `currentBet`.
     */
    function endCurrentRound() external onlyOwner onlyDuringPhase(Phase.Betting) {
        for (uint256 i = 0; i < activePlayers.length; i++) {
            address player = activePlayers[i];
            if (players[player].currentBet < currentBet) {
                revert("Poker Game: Not all players have matched the current bet");
            }
        }
        currentPhase = Phase.Showdown;
    }

    /**
     * @notice Advances the game to the next phase.
     * @dev Can only be called by the contract owner during the Betting phase.
     *      Increments the `currentPhase` enum to move to the next phase.
     */
    function advancePhase() external onlyOwner onlyDuringPhase(Phase.Betting) {
        currentPhase = Phase(uint256(currentPhase) + 1);
    }

    /**
     * @notice Allows a player to place a bet during the Betting phase.
     * @dev Updates the player's chip count, current bet, and the total pot.
     *      Emits a `BetPlaced` event upon successful bet placement.
     *      Automatically folds the player if they have bet all their chips (go all-in).
     * @param amount The amount of chips the player wants to bet.
     *
     * Requirements:
     *
     * - The game must be in the Betting phase.
     * - The player must be active in the current round.
     * - The player must have sufficient chips to place the bet.
     */
    function placeBet(uint256 amount) external onlyDuringPhase(Phase.Betting) {
        address player = msg.sender;
        require(players[player].isActive, "Poker Game: Player is not active in this round");
        require(players[player].chips >= amount, "Poker Game: Insufficient chips");

        uint256 betAmount = amount > currentBet ? amount - currentBet : 0;
        players[player].chips -= betAmount;
        players[player].currentBet += betAmount;
        totalPot += betAmount;
        currentBet = amount;

        emit BetPlaced(player, amount);

        if (players[player].currentBet == players[player].chips) {
            fold(player);
        }
    }

    /**
     * @notice Allows a player to fold, removing them from the current round.
     * @dev Marks the player as inactive and removes them from the `activePlayers` array.
     *      Emits a `PlayerFolded` event upon successful folding.
     * @param player The address of the player who wants to fold.
     *
     * Requirements:
     *
     * - The game must be in the Betting phase.
     * - The player must be active in the current round.
     */
    function fold(address player) public onlyDuringPhase(Phase.Betting) {
        require(players[player].isActive, "Poker Game: Player is not active in this round");

        players[player].isActive = false;
        for (uint256 i = 0; i < activePlayers.length; i++) {
            if (activePlayers[i] == player) {
                activePlayers[i] = activePlayers[activePlayers.length - 1];
                activePlayers.pop();
                emit PlayerFolded(player);
                break;
            }
        }
    }

    /**
     * @notice Allows a player to call the current highest bet.
     * @dev Updates the player's chip count, current bet, and the total pot.
     *      Emits a `PlayerCalled` event upon successful call.
     *
     * Requirements:
     *
     * - The game must be in the Betting phase.
     * - The player must be active in the current round.
     * - The player must have sufficient chips to call the bet.
     */
    function call() external onlyDuringPhase(Phase.Betting) {
        address player = msg.sender;
        require(players[player].isActive, "Poker Game: Player is not active in this round");
        uint256 betAmount = currentBet - players[player].currentBet;

        require(players[player].chips >= betAmount, "Poker Game: Insufficient chips");
        players[player].chips -= betAmount;
        players[player].currentBet += betAmount;
        totalPot += betAmount;

        emit PlayerCalled(player, betAmount);
    }

    /**
     * @notice Allows a player to raise the current bet.
     * @dev Increases the `currentBet` and updates the player's chip count and current bet.
     *      Emits a `PlayerRaised` event upon successful raise.
     * @param amount The new total bet amount after the raise.
     *
     * Requirements:
     *
     * - The game must be in the Betting phase.
     * - The player must be active in the current round.
     * - The player must have sufficient chips to raise the bet.
     */
    function raise(uint256 amount) external onlyDuringPhase(Phase.Betting) {
        address player = msg.sender;
        require(players[player].isActive, "Poker Game: Player is not active in this round");

        uint256 betAmount = amount > currentBet ? amount - currentBet : 0;
        require(players[player].chips >= betAmount, "Poker Game: Insufficient chips");

        players[player].chips -= betAmount;
        players[player].currentBet += betAmount;
        totalPot += betAmount;
        currentBet = amount;

        emit PlayerRaised(player, amount);
    }

    /**
     * @notice Allows a player to go all-in by betting all their remaining chips.
     * @dev Updates the player's chip count and current bet.
     *      Automatically folds the player as they have no chips left.
     *      Emits a `PlayerAllIn` event upon successful all-in.
     * @param amount The amount of chips the player wants to bet (can be less than or equal to their total chips).
     *
     * Requirements:
     *
     * - The game must be in the Betting phase.
     * - The player must be active in the current round.
     */
    function handleAllIn(uint256 amount) external onlyDuringPhase(Phase.Betting) {
        address player = msg.sender;
        require(players[player].isActive, "Poker Game: Player is not active in this round");

        uint256 betAmount = amount > players[player].chips ? players[player].chips : amount;
        players[player].currentBet += betAmount;
        players[player].chips -= betAmount;
        totalPot += betAmount;
        fold(player);

        emit PlayerAllIn(player, betAmount);
    }

    /**
     * @notice Removes a player from the active players list, marking them as inactive.
     * @dev Can only be called by the contract owner during the Betting phase.
     *      Emits a `PlayerFolded` event upon successful removal.
     * @param player The address of the player to remove from the active list.
     *
     * Requirements:
     *
     * - The game must be in the Betting phase.
     * - The player must be active in the current round.
     */
    function removePlayerFromActiveList(address player) external onlyOwner onlyDuringPhase(Phase.Betting) {
        require(players[player].isActive, "Poker Game: Player is not active in this round");
        players[player].isActive = false;

        for (uint256 i = 0; i < activePlayers.length; i++) {
            if (activePlayers[i] == player) {
                activePlayers[i] = activePlayers[activePlayers.length - 1];
                activePlayers.pop();
                emit PlayerFolded(player);
                break;
            }
        }
    }

    /**
     * @notice Starts a new betting round after the Showdown phase.
     * @dev Can only be called by the contract owner during the Showdown phase.
     *      Resets the round and transitions the game phase back to Betting.
     */
    function startNewRound() external onlyOwner onlyDuringPhase(Phase.Showdown) {
        currentPhase = Phase.Betting;
        resetRound();
    }

    /**
     * @notice Ends the game by interacting with the RoomManagement contract.
     * @dev Can only be called by the contract owner during the Showdown phase.
     *      Calls the `endGame` function on the RoomManagement contract.
     *      Transitions the game phase to NotStarted.
     */
    function endGame() external onlyOwner onlyDuringPhase(Phase.Showdown) {
        roomManagement.endGame();

        currentPhase = Phase.NotStarted;
    }

    /**
     * @notice Determines the winners of the current round based on hand evaluations.
     * @dev Can only be called by the contract owner.
     *      Iterates through all players, evaluates their hands, and identifies the highest hand value.
     *      Collects all players with the highest hand value as winners.
     * @return finalWinners An array of addresses representing the winners of the round.
     *
     * Requirements:
     *
     * - The game must be in the appropriate phase to determine winners.
     */
    function determineWinners() internal view onlyOwner returns (address[] memory) {        
        address[] memory playersList = roomManagement.getAllPlayers();
        uint256 highestHandValue = 0;
        address[] memory winners = new address[](playersList.length);
        uint256 winnerCount = 0;

        for (uint256 i = 0; i < playersList.length; i++) {
            address player = playersList[i];
            if (!players[player].isActive) continue;

            // Get player's hand and evaluate it
            Card[] memory hand = roomManagement.getPlayerHand(player);
            uint256 handValue = cardManagement.evaluateHand(hand);

            if (handValue > highestHandValue) {
                highestHandValue = handValue;
                winnerCount = 0;
                winners[winnerCount] = player;
                winnerCount++;
            } else if (handValue == highestHandValue) {
                winners[winnerCount] = player;
                winnerCount++;
            }
        }

        // Resize the winners array to the actual number of winners
        address[] memory finalWinners = new address[](winnerCount);
        for (uint256 i = 0; i < winnerCount; i++) {
            finalWinners[i] = winners[i];
        }

        return finalWinners;
    }

    /**
     * @notice Distributes the total pot to the winners of the round.
     * @dev Can only be called by the contract owner during the Showdown phase.
     *      Ensures there are winners before distributing the pot.
     *      Distributes an equal share of the pot to each winner.
     *      Emits a `PotDistributed` event upon successful distribution.
     *      Uses the `nonReentrant` modifier to prevent reentrancy attacks.
     *
     * Requirements:
     *
     * - The game must be in the Showdown phase.
     * - There must be at least one winner.
     */
    function distributePots() internal onlyOwner onlyDuringPhase(Phase.Showdown) nonReentrant {
        address[] memory winners = determineWinners();
        require(winners.length > 0, "Poker Game: No winners determined");
        uint256 share = totalPot / winners.length;

        for (uint256 i = 0; i < winners.length; i++) {
            address winner = winners[i];
            payable(winner).transfer(share);
        }

        emit PotDistributed(winners, share);

        // Reset pot
        totalPot = 0;
    }

    /**
     * @notice Resets the current betting round.
     * @dev Can only be called by the contract owner during the Betting phase.
     *      Calls the internal `resetRound` function to clear the pot and reset player bets.
     */
    function resetBettingRound() external onlyOwner onlyDuringPhase(Phase.Betting) {
        resetRound();
    }
}
