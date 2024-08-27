// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

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

    // Player data
    struct Player {
        address addr;
        uint256 balance;
        bool registered;
        Card[] hand;
    }
    mapping(address => Player) public players;
    address[] public playerAddresses;

    // Card structure
    struct Card {
        uint8 suit;   // 0 = Spades, 1 = Hearts, 2 = Diamonds, 3 = Clubs
        uint8 value;  // 2-14 (11=Jack, 12=Queen, 13=King, 14=Ace)
    }

    // Events
    event PlayerRegistered(address player);
    event CardDealt(address player, uint256 card);
    event TurnManaged(address player);
    event WinnerDeclared(address winner);

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

    // Modifier to restrict access
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier isGameActive() {
        require(gameActive, "Game is not active");
        _;
    }

    // Player Registration
    function registerPlayer() external {
        require(!players[msg.sender].registered, "Player already registered");
        
        players[msg.sender] = Player({
            addr: msg.sender,
            balance: 0,
            registered: true,
            hand: new Card 
        });

        playerAddresses.push(msg.sender);
        emit PlayerRegistered(msg.sender);
    }

    // Start the Game
    function startGame() external onlyOwner {
        require(!gameActive, "Game is already active");
        require(playerAddresses.length > 1, "Not enough players to start the game");
        
        gameActive = true;
        currentPot = 0;
        currentPlayerIndex = 0;

        collectBuyIns();
        requestRandomness(keyHash, fee);
    }

    // Collect Buy-ins
    function collectBuyIns() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            require(players[player].balance >= buyInAmount, "Insufficient buy-in amount");
            players[player].balance -= buyInAmount;
            currentPot += buyInAmount;
        }
    }

    // Deal Cards
    function dealCards(uint256 randomness) internal isGameActive {
        shuffleDeck(randomness);

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            players[player].hand.push(drawCard());
            players[player].hand.push(drawCard());
            emit CardDealt(player, 2); // Assume 2 cards dealt
        }
    }

    // Draw a card from the deck
    function drawCard() internal returns (Card memory) {
        uint256 cardIndex = deck[deck.length - 1];
        deck.pop();
        return Card(uint8(cardIndex / 13), uint8(cardIndex % 13) + 2);
    }

    // Shuffle the deck using randomness
    function shuffleDeck(uint256 randomness) internal {
        for (uint256 i = 0; i < deck.length; i++) {
            uint256 n = i + (randomness % (deck.length - i));
            uint256 temp = deck[n];
            deck[n] = deck[i];
            deck[i] = temp;
            randomness = randomness / 52;
        }
    }

    // Fulfill Randomness Callback
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        dealCards(randomness);
    }

    // Player Turn Management
    function manageTurn() external isGameActive {
        require(msg.sender == playerAddresses[currentPlayerIndex], "Not your turn to play");
        emit TurnManaged(msg.sender);
        nextPlayerTurn();
    }

    // Move to the next player's turn
    function nextPlayerTurn() internal {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerAddresses.length;
    }

    // End the game and declare a winner
    function endGame(address _winner) external onlyOwner isGameActive {
        require(playerAddresses.length > 0, "No players in the game");
        players[_winner].balance += currentPot;
        currentPot = 0;
        gameActive = false;
        resetPlayerHands();
        initializeDeck();
        emit WinnerDeclared(_winner);
    }

    // Reset player hands
    function resetPlayerHands() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            delete players[playerAddresses[i]].hand;
        }
    }

    // Initialize the deck with 52 cards
    function initializeDeck() internal {
        deck = new uint256 ;
        for (uint256 i = 0; i < 52; i++) {
            deck[i] = i; // 0-51 representing a deck of cards
        }
    }
}
