// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract PokerGame is VRFConsumerBase {

    uint256 public fee;
    bytes32 public keyHash;

    // Struct to Player
    struct Player {
        address addr;
        uint256 balance;
        bool registered;
    }

    // Struct to represent a card
    struct Card {
        uint8 suit;   // 0 = Spades, 1 = Hearts, 2 = Diamonds, 3 = Clubs
        uint8 value;  // 2-14 (11=Jack, 12=Queen, 13=King, 14=Ace)
    }
    
    mapping(address => Player) public players;

    // State variables
    address public owner;
    uint256 public buyInAmount;
    uint256 public currentPot;
    address[] public players;
    mapping(address => uint256) public playerBalances;
    mapping(address => Card[]) public playerHands;
    bool public gameActive;
    uint256[] public deck;
    uint256 public currentPlayerIndex;
    bytes32 internal keyHash;
    uint256 internal fee;

    //Events
    event PlayerRegistered(address player);
    event CardDealt(address player, uint256 card);
    event TurnManaged(address player);
    event WinnerDeclared(address winner);    

    // Constructor
    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee) 
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        owner = msg.sender;
        buyInAmount = 0.1 ether; // Example buy-in amount
        gameActive = false;
        keyHash = _keyHash;
        fee = _fee;
        initializeDeck();
    }

    // Modifier to restrict access
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Modifier to check if the game is active
    modifier isGameActive() {
        require(gameActive, "Game is not active");
        _;
    }

    // Initialize the deck with 52 cards
    function initializeDeck() internal {
        deck = new uint256 ;
        for (uint256 i = 0; i < 52; i++) {
            deck[i] = i; // 0-51 representing a deck of cards
        }
    }

    // Start the game, only the owner can start the game
    function startGame() public onlyOwner {
        require(!gameActive, "Game is already active");
        require(players.length > 1, "Not enough players to start the game");
        
        gameActive = true;
        currentPlayerIndex = 0;
        currentPot = 0;

        // Collect buy-ins and reset balances
        for (uint256 i = 0; i < players.length; i++) {
            require(playerBalances[players[i]] >= buyInAmount, "Insufficient buy-in amount");
            playerBalances[players[i]] -= buyInAmount;
            currentPot += buyInAmount;
        }

        // Shuffle the deck and deal cards
        requestRandomness(keyHash, fee);
    }

    // Request randomness for shuffling the deck
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        return requestRandomness(_keyHash, _fee);
    }

    // Fulfill the randomness request
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Shuffle the deck using the randomness
        for (uint256 i = 0; i < deck.length; i++) {
            uint256 n = i + (randomness % (deck.length - i));
            uint256 temp = deck[n];
            deck[n] = deck[i];
            deck[i] = temp;
            randomness = randomness / 52;
        }

        // Deal cards to players
        dealCards();
    }

    // Deal two cards to each player
    function dealCards() internal isGameActive {
        for (uint256 i = 0; i < players.length; i++) {
            playerHands[players[i]].push(Card(uint8(deck[i] / 13), uint8(deck[i] % 13) + 2));
            playerHands[players[i]].push(Card(uint8(deck[i + players.length] / 13), uint8(deck[i + players.length] % 13) + 2));
        }
        currentPlayerIndex = 0; // Reset to first player
    }

    // Player betting action
    function placeBet(uint256 amount) public isGameActive {
        require(playerBalances[msg.sender] >= amount, "Insufficient balance to place bet");
        require(players[currentPlayerIndex] == msg.sender, "Not your turn to bet");
        
        playerBalances[msg.sender] -= amount;
        currentPot += amount;
        nextPlayerTurn();
    }

    // Move to the next player's turn
    function nextPlayerTurn() internal {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    }

    // End game and distribute winnings
    function endGame(address winner) public onlyOwner isGameActive {
        require(players.length > 0, "No players in the game");

        playerBalances[winner] += currentPot;
        currentPot = 0;
        gameActive = false;

        // Reset player hands
        for (uint256 i = 0; i < players.length; i++) {
            delete playerHands[players[i]];
        }

        initializeDeck(); // Reset the deck
    }

}
