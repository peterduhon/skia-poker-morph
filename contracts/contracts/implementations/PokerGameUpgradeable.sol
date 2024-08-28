// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/IPokerGame.sol";

contract PokerGameUpgradeable is UUPSUpgradeable, IPokerGame {
    address public owner;
    uint256 public buyInAmount;
    uint256 public currentPot;
    bool public gameActive;
    uint256 public currentPlayerIndex;
    uint256[] public deck;
    mapping(bytes32 => bool) public pendingRequests;

    struct Player {
        address addr;
        uint256 balance;
        bool registered;
        bool folded;
        Card[] hand;
    }
    mapping(address => Player) public players;
    address[] public playerAddresses;

    enum Suit { Spades, Hearts, Diamonds, Clubs }
    enum Value { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }

    struct Card {
        Suit suit;
        Value value;
    }

    event PlayerRegistered(address indexed player);
    event CardDealt(address indexed player, Card card);
    event TurnManaged(address indexed player);
    event WinnerDeclared(address indexed winner);
    event RandomnessRequested(bytes32 requestId);
    event RandomnessFailed(bytes32 requestId);
    event GameStarted(address[] players);
    event BetPlaced(address indexed player, uint256 amount);
    event PlayerFolded(address indexed player);

    error NotOwner();
    error AlreadyRegistered(address player);
    error GameAlreadyActive();
    error NotEnoughPlayers(uint256 playerCount);
    error InsufficientBuyIn(uint256 required, uint256 available);
    error InsufficientBalance(address player, uint256 balance, uint256 required);
    error PlayerNotRegistered(address player);
    error NotPlayersTurn(address player);
    error PlayerHasFolded(address player);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyRegistered() {
        if (!players[msg.sender].registered) revert PlayerNotRegistered(msg.sender);
        _;
    }

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        owner = msg.sender;
        buyInAmount = 0.1 ether;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // Ensure only the owner can upgrade the contract
    }

    function registerPlayer() external {
        if (players[msg.sender].registered) revert AlreadyRegistered(msg.sender);

        players[msg.sender] = Player({
            addr: msg.sender,
            balance: 0,
            registered: true,
            folded: false,
            hand: new Card 
        });

        playerAddresses.push(msg.sender);
        emit PlayerRegistered(msg.sender);
    }

    function startGame() external onlyOwner {
        if (gameActive) revert GameAlreadyActive();
        if (playerAddresses.length <= 1) revert NotEnoughPlayers(playerAddresses.length);

        gameActive = true;
        currentPot = 0;
        currentPlayerIndex = 0;

        collectBuyIns();
        initializeDeck();
        shuffleDeck();
        dealInitialCards();
        emit GameStarted(playerAddresses);
    }

    function collectBuyIns() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            if (players[player].balance < buyInAmount) {
                revert InsufficientBuyIn(buyInAmount, players[player].balance);
            }
            players[player].balance -= buyInAmount;
            currentPot += buyInAmount;
        }
    }

    function initializeDeck() internal {
        delete deck; // Clear the deck
        // Initialize the deck with 52 cards
        for (uint8 suit = 0; suit < 4; suit++) {
            for (uint8 value = 0; value < 13; value++) {
                deck.push(suit * 13 + value);
            }
        }
    }

    function shuffleDeck() internal {
        // Simple Fisher-Yates shuffle algorithm
        for (uint256 i = deck.length - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i))) % (i + 1);
            (deck[i], deck[j]) = (deck[j], deck[i]);
        }
    }

    function dealInitialCards() internal {
        // Deal two cards to each player
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            for (uint8 j = 0; j < 2; j++) {
                Card memory card = drawCardFromDeck();
                players[player].hand.push(card);
                emit CardDealt(player, card);
            }
        }
    }

    function drawCardFromDeck() internal returns (Card memory) {
        require(deck.length > 0, "Deck is empty");
        uint256 cardIndex = deck[deck.length - 1];
        deck.pop();
        return Card(Suit(cardIndex / 13), Value(cardIndex % 13));
    }

    function manageTurn() external onlyRegistered {
        if (!gameActive) revert("Game not active");
        if (msg.sender != playerAddresses[currentPlayerIndex]) revert NotPlayersTurn(msg.sender);
        if (players[msg.sender].folded) revert PlayerHasFolded(msg.sender);

        emit TurnManaged(msg.sender);
        nextPlayerTurn();
    }

    function nextPlayerTurn() internal {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerAddresses.length;
    }

    function placeBet(uint256 amount) external onlyRegistered {
        if (!gameActive) revert("Game not active");
        if (players[msg.sender].balance < amount) {
            revert InsufficientBalance(msg.sender, players[msg.sender].balance, amount);
        }

        players[msg.sender].balance -= amount;
        currentPot += amount;

        emit BetPlaced(msg.sender, amount);
    }

    function fold() external onlyRegistered {
        if (!gameActive) revert("Game not active");
        if (players[msg.sender].folded) revert PlayerHasFolded(msg.sender);

        players[msg.sender].folded = true;
        emit PlayerFolded(msg.sender);
        nextPlayerTurn();
    }

    function endGame(address winner) external onlyOwner {
        if (!gameActive) revert("Game not active");

        players[winner].balance += currentPot;
        currentPot = 0;
        gameActive = false;

        resetPlayerStates();
        emit WinnerDeclared(winner);
    }

    function resetPlayerStates() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            delete players[player].hand;
            players[player].folded = false;
        }
    }

    function getPlayerHand(address player) external view onlyRegistered returns (Card[] memory) {
        return players[player].hand;
    }

    function isGameActive() external view returns (bool) {
        return gameActive;
    }

    function getCurrentPlayer() external view returns (address) {
        if (!gameActive) revert("Game not active");
        return playerAddresses[currentPlayerIndex];
    }
}
