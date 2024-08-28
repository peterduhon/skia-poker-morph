// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";

/// @title A contract for a poker game
/// @author James Wong
/// @notice This contract manages a poker game with multiple players
/// @dev All function calls are currently implemented without side effects

contract PokerGame is VRFConsumerBase {
    // Chainlink VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;

    // Game state variables
    address public owner;
    uint256 public buyInAmount;
    uint256 public currentPot;
    bool public gameActive;
    uint256 public currentPlayerIndex;
    uint256[] public deck;
    mapping(bytes32 => bool) public pendingRequests;

    // Player data
    struct Player {
        address addr;
        uint256 balance;
        bool registered;
        bool folded;
        bool isAllIn;
        Card[] hand;  // Each player has a hand of two cards
    }
    mapping(address => Player) public players;
    address[] public playerAddresses;

    // Card suits and values using enums
    enum Suit { Spades, Hearts, Diamonds, Clubs }
    enum Value { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }

    // Card structure using enums
    struct Card {
        Suit suit;
        Value value;
    }

    // Betting round data
    struct BettingRound {
        uint256 betAmount;        // Amount players need to match
        uint256 totalPot;         // Total pot for this round
        mapping(address => uint256) playerBets; // Mapping of player addresses to their bets
        address[] activePlayers;  // Players still active in this round
    }
    BettingRound public currentRound;
    uint256 public roundNumber;

    // Improved Betting Logic
    struct Pot {
        uint256 amount;
        address[] eligiblePlayers;
    }

    Pot public mainPot;
    Pot[] public sidePots;
    
    // Events
    event PlayerRegistered(address indexed player);
    event CardDealt(address indexed player, Card card);
    event TurnManaged(address indexed player);
    event WinnerDeclared(address indexed winner);
    event RandomnessRequested(bytes32 requestId);
    event RandomnessFailed(bytes32 requestId);

    // New events
    event PlayerBetPlaced(address indexed player, uint256 amount);
    event PlayerCalled(address indexed player);
    event PlayerRaised(address indexed player, uint256 amount);
    event PlayerFolded(address indexed player);
    event NewRoundStarted(uint256 roundNumber);
    event RoundEnded(uint256 roundNumber);
    event GameStarted();
    event GameEnded(address indexed winner);

    // Constructor
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        buyInAmount = 0.1 ether;
        keyHash = _keyHash;
        fee = _fee;
        initializeDeck();
    }

    // Modifiers for validation
    modifier onlyOwner() {
        require(msg.sender == owner, "PokerGame: Caller is not the contract owner");
        _;
    }

    modifier isGameActive() {
        require(gameActive, "PokerGame: A game is not active.");
        _;
    }

    modifier isPlayer() {
        require(players[msg.sender].registered, "PokerGame: Player is not registered");
        _;
    }

    modifier isEOA() {
        require(msg.sender.code.length == 0, "PokerGame: Only EOA can call this function");
        _;
    }

    modifier nonReentrant() {
        require(!reentrant, "PokerGame: Reentrancy detected");
        reentrant = true;
        _;
        reentrant = false;
    }

    bool private reentrant;  // State variable to track reentrancy

    // Player Registration with EOA Check
    function registerPlayer() external isEOA {
        require(!players[msg.sender].registered, "PokerGame: Player already registered");

        players[msg.sender] = Player({
            addr: msg.sender,
            balance: 0,
            registered: true,
            folded: false,
            isAllIn: false,
            hand: new Card 
        });

        playerAddresses.push(msg.sender);
        emit PlayerRegistered(msg.sender);
    }

    // Start the Game
    function startGame() external onlyOwner {
        require(!gameActive, "PokerGame: Game is already in progress");
        require(playerAddresses.length > 1, "PokerGame: Not enough players to start the game");
        
        gameActive = true;
        currentPot = 0;
        currentPlayerIndex = 0;

        collectBuyIns();
        bytes32 requestId = requestRandomness(keyHash, fee);
        pendingRequests[requestId] = true;
        emit RandomnessRequested(requestId);
        emit GameStarted();
    }

    // Collect Buy-ins
    function collectBuyIns() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            require(players[player].balance >= buyInAmount, "PokerGame: Player doesn't have sufficient balance for buy-in");
            players[player].balance -= buyInAmount;
            currentPot += buyInAmount;
        }
    }

    // Manage Player's Turn with Validation
    function manageTurn(uint256 betAmount) external isGameActive isPlayer {
        require(msg.sender == playerAddresses[currentPlayerIndex], "PokerGame: Not your turn to play");
        require(!players[msg.sender].folded, "PokerGame: Player has already folded");

        // Handle different actions
        if (betAmount == 0) {
            fold();
        } else if (betAmount == currentRound.betAmount) {
            call();
        } else if (betAmount > currentRound.betAmount) {
            raise(betAmount);
        } else {
            revert("PokerGame: Invalid bet amount");
        }

        emit TurnManaged(msg.sender);
        nextPlayerTurn();
    }

    function placeBet(uint256 amount) public isGameActive isPlayer {
        require(amount >= currentRound.betAmount, "PokerGame: Bet amount too low");
        require(players[msg.sender].balance >= amount, "PokerGame: Player doesn't have sufficient balance");

        players[msg.sender].balance -= amount;
        currentRound.playerBets[msg.sender] += amount;
        currentRound.totalPot += amount;

        emit PlayerBetPlaced(msg.sender, amount);
    }

    function fold() internal {
        players[msg.sender].folded = true;
        removePlayerFromActiveList(msg.sender);
        emit PlayerFolded(msg.sender);
    }

    function call() internal {
        uint256 callAmount = currentRound.betAmount - currentRound.playerBets[msg.sender];
        players[msg.sender].balance -= callAmount;
        currentRound.playerBets[msg.sender] += callAmount;
        currentRound.totalPot += callAmount;

        emit PlayerCalled(msg.sender);
    }

    function raise(uint256 amount) internal {
        require(amount > currentRound.betAmount, "PokerGame: Raise amount too low");
        uint256 raiseAmount = amount - currentRound.betAmount;
        players[msg.sender].balance -= amount;
        currentRound.playerBets[msg.sender] += amount;
        currentRound.totalPot += amount;
        currentRound.betAmount = amount;

        emit PlayerRaised(msg.sender, amount);
    }

    function removePlayerFromActiveList(address player) internal {
        // Implementation to remove player from activePlayers array
        for (uint256 i = 0; i < currentRound.activePlayers.length; i++) {
            if (currentRound.activePlayers[i] == player) {
                currentRound.activePlayers[i] = currentRound.activePlayers[currentRound.activePlayers.length - 1];
                currentRound.activePlayers.pop();
                break;
            }
        }
    }

    function startNewRound() external onlyOwner {
        require(!gameActive, "PokerGame: Game is already in progress");
        roundNumber++;
        currentRound = BettingRound({
            betAmount: buyInAmount,
            totalPot: 0,
            activePlayers: playerAddresses
        });
        emit NewRoundStarted(roundNumber);
    }

    function endCurrentRound() external onlyOwner {
        // Logic to resolve betting round, determine actions, and prepare for the next round
        resetRound();
    }

    function resetRound() internal {
        // Reset currentRound state variables for the next round
        currentRound.betAmount = 0;
        currentRound.totalPot = 0;
        delete currentRound.activePlayers;
        emit RoundEnded(roundNumber);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (!pendingRequests[requestId] || !gameActive) {
            emit RandomnessFailed(requestId);
            return; // Request ID is not recognized or game is inactive
        }

        pendingRequests[requestId] = false; // Mark the request as fulfilled
        dealCards(randomness);
    }

    function dealCards(uint256 randomness) internal isGameActive {
        shuffleDeck(randomness);

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            players[player].hand.push(drawCard());
            players[player].hand.push(drawCard()); // Dealing two cards per player
            emit CardDealt(player, players[player].hand[0]);
            emit CardDealt(player, players[player].hand[1]);
        }
    }

    function drawCard() internal returns (Card memory) {
        uint256 cardIndex = deck[deck.length - 1];
        deck.pop();
        return Card(Suit(cardIndex / 13), Value(cardIndex % 13));
    }

    function shuffleDeck(uint256 randomness) internal {
        // Implementation of shuffle deck using randomness
        uint256 length = deck.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 j = (randomness % (length - i)) + i;
            (deck[i], deck[j]) = (deck[j], deck[i]);
        }
    }

    function initializeDeck() internal {
        for (uint256 i = 0; i < 52; i++) {
            deck.push(i);
        }
    }

    function nextPlayerTurn() internal {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerAddresses.length;
    }

    function endGame(address winner) external onlyOwner {
        require(gameActive, "PokerGame: Game is not in progress");
        gameActive = false;
        emit GameEnded(winner);
    }
}
