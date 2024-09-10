// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./HandEvaluator.sol";
import "./UserManagement.sol";

contract GameManagement is Ownable, AccessControl {
    HandEvaluator public handEvaluator;
    UserManagement public userManagement;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum GameStatus { Waiting, Active, Completed }
    
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

    constructor(address _handEvaluator, address _userManagement) {
        handEvaluator = HandEvaluator(_handEvaluator);
        userManagement = UserManagement(_userManagement);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Creates a new game room.
     * @param _buyInAmount The buy-in amount for the game.
     * @param _maxPlayers The maximum number of players allowed in the game.
     */
    function createGameRoom(uint256 _buyInAmount, uint256 _maxPlayers) external onlyRole(ADMIN_ROLE) {
        require(_buyInAmount > 0, "Buy-in amount must be greater than 0");
        require(_maxPlayers > 1, "Number of players must be greater than 1");

        uint256 gameId = nextGameId++;
        GameRoom memory newRoom = GameRoom({
            id: gameId,
            creator: msg.sender,
            buyInAmount: _buyInAmount,
            maxPlayers: _maxPlayers,
            createdAt: block.timestamp,
            status: GameStatus.Waiting
        });

        gameRooms[gameId] = newRoom;
        userGames[msg.sender].push(gameId);
        handEvaluator.setGameId(gameId);
        emit GameRoomCreated(gameId, msg.sender, _buyInAmount, _maxPlayers);
    }

    function createAndStartGame(uint256 _buyInAmount, uint256 _maxPlayers) external onlyRole(ADMIN_ROLE) {
    uint256 gameId = nextGameId++;
    GameRoom memory newRoom = GameRoom({
        id: gameId,
        creator: msg.sender,
        buyInAmount: _buyInAmount,
        maxPlayers: _maxPlayers,
        createdAt: block.timestamp,
        status: GameStatus.Active
    });
    gameRooms[gameId] = newRoom;
    
    handEvaluator.startGame(gameId, _buyInAmount, _maxPlayers);
    
    emit GameRoomCreated(gameId, msg.sender, _buyInAmount, _maxPlayers);
}

function endGame(address[] memory winners) public onlyOwner {
    handEvaluator.endGame(winners);
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
