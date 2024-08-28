// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IPokerGame.sol";

contract PokerGameImplementation is IPokerGame {
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

    error AlreadyRegistered(address player);
    error GameAlreadyActive();
    error NotEnoughPlayers(uint256 playerCount);
    error InsufficientBuyIn(uint256 required, uint256 available);
    error InsufficientBalance(address player, uint256 balance, uint256 required);
    error PlayerNotRegistered(address player);
    error NotPlayersTurn(address player);

    function initialize() public {
        owner = msg.sender;
        buyInAmount = 0.1 ether;
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
        bytes32 requestId = requestRandomness(keyHash, fee);
        pendingRequests[requestId] = true;
        emit RandomnessRequested(requestId);
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

    function manageTurn() external {
        if (!gameActive) revert("Game not active");
        if (!players[msg.sender].registered) revert PlayerNotRegistered(msg.sender);
        if (msg.sender != playerAddresses[currentPlayerIndex]) revert NotPlayersTurn(msg.sender);
        if (players[msg.sender].folded) revert("Player has folded");

        emit TurnManaged(msg.sender);
        nextPlayerTurn();
    }

    function nextPlayerTurn() internal {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerAddresses.length;
    }

    function endGame(address _winner) external onlyOwner {
        if (playerAddresses.length == 0) revert("No players in game");
        players[_winner].balance += currentPot;
        currentPot = 0;
        gameActive = false;
        resetPlayerHands();
        initializeDeck();
        emit WinnerDeclared(_winner);
    }

    function resetPlayerHands() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            delete players[playerAddresses[i]].hand;
        }
    }

    function initializeDeck() internal {
        for (uint256 i = 0; i < 52; i++) {
            deck.push(i);
        }
    }
}
