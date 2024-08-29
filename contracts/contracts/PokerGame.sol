// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PokerGame is VRFConsumerBase, Ownable, ReentrancyGuard {
    // Chainlink VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;

    // Game state variables
    uint256 public buyInAmount;
    uint256 public currentPot;
    bool public gameActive;
    uint256 public currentPlayerIndex;
    uint256[] public deck;
    mapping(bytes32 => bool) public pendingRequests;

    // Card suits and values using enums
    enum Suit { Spades, Hearts, Diamonds, Clubs }
    enum Value { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }
    enum HandRanking {
        HighCard,
        Pair,
        TwoPairs,
        ThreeOfAKind,
        Straight,
        Flush,
        FullHouse,
        FourOfAKind,
        StraightFlush,
        RoyalFlush
    }

    // Card structure using enums
    struct Card {
        Suit suit;
        Value value;
    }

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

    // Betting round data
    struct BettingRound {
        uint256 betAmount;        // Amount players need to match
        uint256 totalPot;         // Total pot for this round
        mapping(address => uint256) playerBets;
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
    event RandomnessReceived(uint256 randomness);
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
        buyInAmount = 0.1 ether;
        keyHash = _keyHash;
        fee = _fee;
        initializeDeck();
    }

    // Modifiers for validation
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

    // Player Registration with EOA Check
    function registerPlayer() external isEOA {
        require(!players[msg.sender].registered, "PokerGame: Player already registered");

        players[msg.sender].addr = msg.sender;
        players[msg.sender].balance = 0;
        players[msg.sender].registered = true;
        players[msg.sender].folded = false;
        players[msg.sender].isAllIn = false;

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
    function manageTurn(uint256 betAmount) external isGameActive isPlayer nonReentrant {
        require(msg.sender == playerAddresses[currentPlayerIndex], "PokerGame: Not your turn to play");
        require(!players[msg.sender].folded, "PokerGame: Player has already folded");

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

    function nextPlayerTurn() internal {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerAddresses.length;
        while (players[playerAddresses[currentPlayerIndex]].folded && playerAddresses.length > 1) {
            currentPlayerIndex = (currentPlayerIndex + 1) % playerAddresses.length;
        }
    }

    function placeBet(uint256 amount) public isGameActive isPlayer nonReentrant {
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
        players[msg.sender].balance -= raiseAmount;
        currentRound.playerBets[msg.sender] += raiseAmount;
        currentRound.totalPot += raiseAmount;
        currentRound.betAmount = amount;

        emit PlayerRaised(msg.sender, raiseAmount);
    }

    function removePlayerFromActiveList(address player) internal {
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

        currentRound.betAmount = buyInAmount;
        currentRound.totalPot = 0;
        currentRound.activePlayers = playerAddresses;
        for (uint256 i = 0; i < currentRound.activePlayers.length; i++) currentRound.playerBets[playerAddresses[i]] = 0;
        emit NewRoundStarted(roundNumber);
    }

    function endCurrentRound() external onlyOwner isGameActive {
        require(currentRound.activePlayers.length > 1, "PokerGame: Not enough players to continue.");

        address[] memory activePlayers = currentRound.activePlayers;

        if (activePlayers.length == 1) {
            address winner = activePlayers[0];
            players[winner].balance += currentRound.totalPot;
            emit WinnerDeclared(winner);
            gameActive = false;
        } else {
            mainPot.amount += currentRound.totalPot;
        }

        resetRound();
        emit RoundEnded(roundNumber);
        roundNumber++;
    }

    function resetRound() internal {
        currentRound.betAmount = 0;
        currentRound.totalPot = 0;
        delete currentRound.activePlayers;
        emit RoundEnded(roundNumber);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (!pendingRequests[requestId] || !gameActive) {
            emit RandomnessFailed(requestId);
            return;
        }
        pendingRequests[requestId] = false;
        shuffleDeck(randomness);
        dealCardsToPlayers();
        emit RandomnessReceived(randomness);
    }

    function shuffleDeck(uint256 randomness) internal {
        uint256 deckLength = deck.length;
        for (uint256 i = 0; i < deckLength; i++) {
            uint256 j = randomness % deckLength;
            (deck[i], deck[j]) = (deck[j], deck[i]);
        }
    }

    function initializeDeck() internal {
        uint256 index = 0;
        for (uint256 suit = 0; suit < 4; suit++) {
            for (uint256 value = 0; value < 13; value++) {
                deck[index] = suit * 13 + value;
                index++;
            }
        }
    }

    function dealCardsToPlayers() internal {
        require(deck.length >= playerAddresses.length * 2, "PokerGame: Not enough cards in the deck");
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            Player storage player = players[playerAddresses[i]];
            player.hand.push(Card({
                suit: Suit(deck[0] / 13),
                value: Value(deck[0] % 13)
            }));
            deck = removeCardFromDeck(0);
            player.hand.push(Card({
                suit: Suit(deck[0] / 13),
                value: Value(deck[0] % 13)
            }));
            deck = removeCardFromDeck(0);
            emit CardDealt(playerAddresses[i], player.hand[0]);
            emit CardDealt(playerAddresses[i], player.hand[1]);
        }
    }

    function removeCardFromDeck(uint256 index) internal returns (uint256[] memory) {
        uint256[] memory newDeck = new uint256[](deck.length - 1);
        for (uint256 i = 0; i < index; i++) {
            newDeck[i] = deck[i];
        }
        for (uint256 i = index; i < newDeck.length; i++) {
            newDeck[i] = deck[i + 1];
        }
        return newDeck;
    }

    function getDeck() public view returns (uint256[] memory) {
        return deck;
    }

    function getPlayerHand(address player) public view returns (Card[] memory) {
        return players[player].hand;
    }

    function getPlayer(address player) public view returns (Player memory) {
        return players[player];
    }

    function endGame() external onlyOwner isGameActive {
        require(playerAddresses.length == 1, "PokerGame: More than one player remaining");
        address winner = playerAddresses[0];
        players[winner].balance += currentPot;
        emit GameEnded(winner);
        gameActive = false;
    }
}
