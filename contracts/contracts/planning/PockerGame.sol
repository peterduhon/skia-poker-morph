// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";
import "./GameManagement.sol";

contract PokerGame is Ownable, VRFConsumerBase {
    enum GameState { WaitingForPlayers, InProgress, Finished }
    enum PlayerAction { None, Fold, Call, Raise }

    struct Player {
        address playerAddress;
        uint256 balance;
        PlayerAction action;
    }

    struct Game {
        uint256 id;
        address creator;
        uint256 buyInAmount;
        uint256 maxPlayers;
        uint256 pot;
        GameState state;
        address[] players;
        address[] activePlayers;
        uint256[] cardDeck; // Array to hold card deck for the game
    }

    uint256 public nextGameId;
    mapping(uint256 => Game) public games;
    mapping(uint256 => mapping(address => Player)) public playerInfo; // Track player information separately
    GameManagement public gameManagement;

    // Chainlink VRF setup
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => uint256) public requestIdToGameId;

    event GameStarted(uint256 indexed gameId);
    event PlayerJoined(uint256 indexed gameId, address player);
    event PlayerActionTaken(uint256 indexed gameId, address player, PlayerAction action);
    event GameEnded(uint256 indexed gameId, address winner);

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee, address _gameManagement) 
        VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;
        gameManagement = GameManagement(_gameManagement);
    }

    function startGame(uint256 _gameId) external onlyOwner {
        Game storage game = games[_gameId];
        require(game.state == GameState.WaitingForPlayers, "Game is not in a valid state to start");
        require(game.players.length >= 2, "Not enough players to start the game");

        game.state = GameState.InProgress;
        game.pot = game.buyInAmount * game.players.length;

        // Request randomness from Chainlink VRF
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToGameId[requestId] = _gameId;

        emit GameStarted(_gameId);
    }

    function joinGame(uint256 _gameId) external payable {
        Game storage game = games[_gameId];
        require(game.state == GameState.WaitingForPlayers, "Game is not open for joining");
        require(game.players.length < game.maxPlayers, "Game room is full");
        require(msg.value == game.buyInAmount, "Incorrect buy-in amount");

        game.players.push(msg.sender);
        playerInfo[_gameId][msg.sender] = Player({
            playerAddress: msg.sender,
            balance: msg.value,
            action: PlayerAction.None
        });

        emit PlayerJoined(_gameId, msg.sender);
    }

    function takeAction(uint256 _gameId, PlayerAction _action) external {
        Game storage game = games[_gameId];
        require(game.state == GameState.InProgress, "Game is not in progress");
        require(playerInfo[_gameId][msg.sender].playerAddress == msg.sender, "Not a player in this game");

        playerInfo[_gameId][msg.sender].action = _action;

        emit PlayerActionTaken(_gameId, msg.sender, _action);

        // Game logic to handle actions will go here
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 gameId = requestIdToGameId[requestId];
        Game storage game = games[gameId];
        
        // Use randomness to shuffle and deal cards, etc.
        // Example: game.cardDeck = shuffleDeck(randomness);
    }

    function endGame(uint256 _gameId) external onlyOwner {
        Game storage game = games[_gameId];
        require(game.state == GameState.InProgress, "Game is not in progress");

        // Determine winner and distribute pot
        // Example: address winner = determineWinner(game);
        address winner = address(0); // Placeholder, implement logic to determine the winner
        game.state = GameState.Finished;
        game.pot = 0;

        // Transfer winnings
        payable(winner).transfer(game.pot);

        emit GameEnded(_gameId, winner);
    }

    function createGame(uint256 _buyInAmount, uint256 _maxPlayers) external onlyOwner {
        uint256 gameId = nextGameId++;
        Game storage newGame = games[gameId];
        
        newGame.id = gameId;
        newGame.creator = msg.sender;
        newGame.buyInAmount = _buyInAmount;
        newGame.maxPlayers = _maxPlayers;
        newGame.state = GameState.WaitingForPlayers;

        emit GameStarted(gameId);
    }

    // Getter functions
    function getGameDetails(uint256 _gameId) external view returns (
        address creator,
        uint256 buyInAmount,
        uint256 maxPlayers,
        uint256 pot,
        GameState state,
        address[] memory players,
        address[] memory activePlayers
    ) {
        Game storage game = games[_gameId];
        return (
            game.creator,
            game.buyInAmount,
            game.maxPlayers,
            game.pot,
            game.state,
            game.players,
            game.activePlayers
        );
    }

    function getPlayerInfo(uint256 _gameId, address _player) external view returns (
        uint256 balance,
        PlayerAction action
    ) {
        Player storage player = playerInfo[_gameId][_player];
        return (player.balance, player.action);
    }
}
