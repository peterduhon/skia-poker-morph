// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";
import "./Cards.sol";
import "./Actions.sol";
import "./Users.sol";
import "./Games.sol";

contract RoomManagement is Ownable, VRFConsumerBase {
    address private vrfCoordinatorAddress;
    address private linkTokenAddress;

    bytes32 private keyHash;
    uint256 private fee;
    uint256 public seed;

    enum GameStatus { Waiting, Active, Completed }
    enum PlayerAction { Begin, Fold, Raise, Call, Check, AllIn }
    enum Suit { Spades, Hearts, Diamonds, Clubs }
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

    struct Player {
        address addr;
        string nickName;
        uint256 chips;
        uint256 position;
        PlayerAction status;
    }

    struct GameRoom {
        uint256 id;
        address creator;
        uint256 buyInAmount;
        uint256 maxPlayers;
        uint256 createdAt;
        GameStatus status;
    }
    GameRoom currentGameRoom;
    mapping(address => Card[]) playerHands;
    Player[] players;
    Card[52] deck;
    Card[] communityCards;
    uint256 playersCount;

    struct User {
        address userAddress;
        string username;
        uint256 balance;
    }

    enum GamePhase { NotStarted, Registration, BuyIn, Playing, Ended }
    GamePhase public currentPhase;

    CardManagement public cardManagement;
    BettingAndPotManagement public bettingAndPotManagement;
    UserManagement public userManagement;
    GameManagement public gameManagement;

    modifier onlyDuringPhase(GamePhase phase) {
        require(currentPhase == phase, "Invalid game phase");
        _;
    }

    // Events
    event DeckInitialized();
    event CardsDealtToPlayers();
    event CommunityCardsDealt();
    
    constructor(
        address _cardManagementAddress,
        address _bettingAndPotManagementAddress,
        address _userManagementAddress,
        address _gameManagementAddress,
        uint256 _gameID,
        address vrfCoordinator,
        address _linkTokenAddress,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(vrfCoordinator, _linkTokenAddress) {
        cardManagement = CardManagement(_cardManagementAddress);
        bettingAndPotManagement = BettingAndPotManagement(_bettingAndPotManagementAddress);
        userManagement = UserManagement(_userManagementAddress);
        gameManagement = GameManagement(_gameManagementAddress);
        GameRoom memory _game = gameManagement.getGameRoom(_gameID);
        currentGameRoom = _game;

        vrfCoordinatorAddress = vrfCoordinator;
        linkTokenAddress = _linkTokenAddress;
        LINK = LinkTokenInterface(_linkTokenAddress);
        keyHash = _keyHash;
        fee = _fee;
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
    function registerPlayer(address player) external onlyDuringPhase(GamePhase.Registration) {
        User memory _user = userManagement.getUserProfile(player);
        require(currentGameRoom.maxPlayers > currentGameRoom.playersCount, "Poker Game : The Room is full.");
        require(_user.balance >= currentGameRoom.buyInAmount, "Pocker Game : Not enough balance to join game.");
        uint currentIndex = currentGameRoom.playersCount;
        currentGameRoom.players[currentIndex].addr = player;
        currentGameRoom.players[currentIndex].nickName = _user.name;
        currentGameRoom.players[currentIndex].chips = currentGameRoom.buyInAmount;
        currentGameRoom.players[currentIndex].status = PlayerAction.Begin;
        currentGameRoom.players[currentIndex].position = currentIndex;
        currentGameRoom.playersCount++;
    }

    /**
     * @dev Starts a new round of the game.
     */
    function startNewRound() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        initializeDeck();
        shuffleDeck();
        bettingAndPotManagement.resetRound();
    }

    /**
     * @dev Initializing Decks
     */
    function initializeDeck() internal {
        uint8 i = 0;
        for (uint256 suit = 0; suit < 4; suit++) {
            for (uint256 value = 0; value < 13; value++) {
                deck[i++] = (Card(uint8(suit), uint8(value)));
            }
        }
        emit DeckInitialized();
    }

    function shuffleDeck() internal {
        require(seed > 0, "Poker Game : Seed not set");
        for (uint i = 0; i < deck.length; i++) {
            uint256 j = uint256(keccak256(abi.encodePacked(seed, i))) % deck.length;
            Card memory temp = deck[i];
            deck[i] = deck[j];
            deck[j] = temp;
        }
    }

    function removeCardFromDeck(uint256 index) internal {
        require(index < deck.length, "Poker Game : Index out of bounds");
        deck[index] = deck[deck.length - 1];
        deck.pop();
    }

    function drawCard() internal returns (Card memory) {
        require(deck.length > 0, "Poker Game : No cards left in the deck");
        uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed))) % deck.length;
        Card memory drawnCard = deck[index];
        removeCardFromDeck(index);
        return drawnCard;
    }

    function dealCardsToPlayers(address[] memory _players) internal {
        require(_players.length > 0, "Poker Game : No players to deal cards to");
        for (uint256 i = 0; i < _players.length; i++) {
            delete playerHands[_players[i]];
            for (uint256 j = 0; j < 2; j++) {
                playerHands[_players[i]].push(drawCard());
            }
        }
        emit CardsDealtToPlayers();
    }

    function getCommunityCards() external view returns (Card[] memory) {
        return communityCards;
    }

    function dealCommunityCards() external onlyOwner {
        require(communityCards.length == 0, "Poker Game : Community cards already dealt");
        // Deal 5 community cards in stages
        for (uint256 i = 0; i < 5; i++) {
            communityCards.push(drawCard());
        }
        emit CommunityCardsDealt();
    }

    /**
     * @dev Resets the current round.
     */
    function resetRound() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        bettingAndPotManagement.resetRound();
    }

    /**
     * @dev Ends the current round.
     */
    function endCurrentRound() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        bettingAndPotManagement.endCurrentRound();
    }

    /**
     * @dev Advances to the next phase of the game.
     */
    function advancePhase() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        bettingAndPotManagement.advancePhase();
    }

    /**
     * @dev Manages the player's turn by processing their action.
     * @param player The address of the player.
     * @param action The action to perform (1: Bet, 2: Fold, 3: Call, 4: Raise, 5: All-in).
     * @param amount The amount involved in the action.
     */
    function manageTurn(address player, uint256 action, uint256 amount) external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        require(action >= 1 && action <= 5, "Poker Game : Invalid action");
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
        return bettingAndPotManagement.isRoundOver();
    }

    /**
     * @dev Moves to the next player's turn.
     */
    function nextPlayerTurn() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        bettingAndPotManagement.nextPlayerTurn();
    }

    /**
     * @dev Removes a player from the active list.
     * @param player The address of the player to remove.
     */
    function removePlayer(address player) external onlyDuringPhase(GamePhase.Playing) {
        uint currentIndex = playersCount;
        for(uint i = 0; i < currentIndex; i++)
            if(players[i].addr == player) {
                players[i] = players[currentIndex];
                players.pop();
                playersCount--;
                break;
            }
    }

    /**
     * @dev Ends the game and transitions to the Ended phase.
     */
    function endGame() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
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
        return bettingAndPotManagement.determineWinners();
    }

    /**
     * @dev Retrieves the list of winners for side pots.
     * @return Array of winner addresses.
     */
    function determineWinnersForSidePot() external view returns (address[] memory) {
        return bettingAndPotManagement.determineWinnersForSidePot();
    }

    /**
     * @dev Distributes pots at the end of the game.
     */
    function distributePots() external onlyOwner onlyDuringPhase(GamePhase.Ended) {
        bettingAndPotManagement.distributePots();
    }

    /**
     * @dev Resets the betting round.
     */
    function resetBettingRound() external onlyOwner onlyDuringPhase(GamePhase.Playing) {
        bettingAndPotManagement.resetBettingRound();
    }

    /**
     * @dev Evaluates a hand of cards.
     * @param hand The hand of cards to evaluate.
     * @return The strength of the hand.
     */
    function evaluateHand(Card[] memory hand) external view returns (uint256) {
        return cardManagement.evaluateHand(hand);
    }

    /**
     * @dev Set seed from chainlink VRF and suffleDeck
     * @param requestId randomness request ID
     * @param randomness requesting randomness
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        seed = randomness;
        shuffleDeck();
    }

    /**
     * @dev RequestRandomness
     */
    function requestRandomness() external onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "Poker Game : Not enough LINK to pay fee");
        requestRandomness(keyHash, fee);
    }

    /**
     * @dev Get room players address as array
     */
    function getAllPlayers() external view returns(address[] memory) {
        address[] memory playerAddresses;
        for(uint i = 0 ; i < playersCount ; i++)
            playerAddresses.push(players[i].addr);
        return playerAddresses;
    }

    /**
     * @dev Get buyInAmount of this room
     */
    function getBuyInAmount() external view returns(uint256) {
        return currentGameRoom.buyInAmount;
    }

}
