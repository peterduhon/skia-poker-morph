// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title GameManagement
 * @dev This contract manages game rooms, including creation and status updates.
 */
contract GameManagement is Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

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
    
    uint256 public nextGameId;
    mapping(uint256 => GameRoom) public gameRooms;
    mapping(address => uint256[]) public userGames; // Track games by user address

    event GameRoomCreated(uint256 indexed gameId, address indexed creator, uint256 buyInAmount, uint256 maxPlayers);
    event GameRoomStatusUpdated(uint256 indexed gameId, GameStatus newStatus);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Creates a new game room.
     * @param _buyInAmount The buy-in amount for the game.
     * @param _maxPlayers The maximum number of players allowed in the game.
     * @return The ID of the newly created game room.
     */
    function createGameRoom(uint256 _buyInAmount, uint256 _maxPlayers) external onlyRole(ADMIN_ROLE) returns (uint256) {
        require(_buyInAmount > 0, "Buy-in amount must be greater than 0");
        require(_maxPlayers > 1, "Number of players must be greater than 1");

        uint256 gameId = nextGameId++;
        gameRooms[gameId].id = gameId;
        gameRooms[gameId].creator = msg.sender;
        gameRooms[gameId].buyInAmount = _buyInAmount;
        gameRooms[gameId].maxPlayers = _maxPlayers;
        gameRooms[gameId].createdAt = block.timestamp;
        gameRooms[gameId].status = GameStatus.Waiting;
    
        userGames[msg.sender].push(gameId);

        emit GameRoomCreated(gameId, msg.sender, _buyInAmount, _maxPlayers);
        return gameId;
    }

    /**
     * @dev Updates the status of a game room.
     * @param _gameId The ID of the game room.
     * @param _status The new status of the game room.
     */
    function updateGameStatus(uint256 _gameId, GameStatus _status) external onlyRole(ADMIN_ROLE) {
        require(gameRooms[_gameId].id == _gameId, "Game room does not exist");
        gameRooms[_gameId].status = _status;

        emit GameRoomStatusUpdated(_gameId, _status);
    }

    /**
     * @dev Retrieves the details of a specific game room.
     * @param _gameId The ID of the game room.
     * @return The details of the game room.
     */
    function getGameRoom(uint256 _gameId) external view returns (GameRoom memory) {
        require(gameRooms[_gameId].id == _gameId, "Game room does not exist");
        return gameRooms[_gameId];
    }

    /**
     * @dev Retrieves the list of game rooms for a specific user.
     * @param _user The address of the user.
     * @return The list of game room IDs associated with the user.
     */
    function getUserGames(address _user) external view returns (uint256[] memory) {
        return userGames[_user];
    }

    /**
     * @dev Grants ADMIN_ROLE to an address.
     * @param account The address to grant the role to.
     */
    function grantAdminRole(address account) public onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }
}
