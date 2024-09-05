// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";
import "./Cards.sol";
import "./Rooms.sol";
import "./Users.sol";
import "./Common.sol";

contract BettingAndPotManagement is Ownable, ReentrancyGuard, VRFConsumerBase {
    GameState public gameState;
    uint256 public minimumBet;
    uint256 public currentBet;
    uint256 public dealerIndex;
    uint256 public currentPlayerIndex;

    address[] public playersList;
    address[] public leavePlayersList;
    mapping(address => Player) public players;
    mapping(address => Card[]) public playerHands;
    Card[] public communityCards;
    Card[] public deck;
    Pot[] public pots;

    CardManagement public cardManagement;
    RoomManagement public roomManagement;
    UserManagement public userManagement;

    uint256 public roomId;

    // Chainlink VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    mapping(bytes32 => address) private requestIdToAddress;

    event GameStarted(uint256 roomId);
    event GameStateChanged(GameState newState);
    event PlayerJoined(address player);
    event PlayerLeft(address player);
    event PlayersLeft(address[] players);
    event PlayerActionTaken(address player, PlayerAction action, uint256 amount);
    event PotCreated(uint256 potIndex, uint256 amount, address[] eligiblePlayers);
    event PotDistributed(uint256 potIndex, uint256 amount, address[] winners);
    event RoundEnded();
    event GameEnded();
    event DeckShuffled();
    event CardsDealt(address indexed player, Card[] hand);
    event CommunityCardsDealt(Card[] communityCards);
    event DeckReset();
    event PlayersInfoUpdated();
    event PlayerListSyncFinished();

    modifier inGameState(GameState _state) {
        require(gameState == _state, "Invalid game state for this action");
        _;
    }

    modifier onlyPlayer() {
        require(players[msg.sender].addr == msg.sender, "Caller is not a registered player");
        _;
    }

    modifier onlyCurrentPlayer() {
        require(playersList[currentPlayerIndex] == msg.sender, "It's not your turn");
        _;
    }

    constructor(
        uint256 _roomId,
        address _cardManagementAddress,
        address _roomManagementAddress,
        address _userManagementAddress,
        uint256 _minimumBet,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        roomId = _roomId;
        cardManagement = CardManagement(_cardManagementAddress);
        roomManagement = RoomManagement(_roomManagementAddress);
        userManagement = UserManagement(_userManagementAddress);
        minimumBet = _minimumBet;
        gameState = GameState.WaitingForPlayers;

        keyHash = _keyHash;
        fee = _fee;
    }

    function requestRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        shuffleDeck();
    }

    function shuffleDeck() internal {
        uint256 deckSize = deck.length;
        for (uint256 i = 0; i < deckSize; i++) {
            uint256 j = randomResult % deckSize;
            Card memory temp = deck[i];
            deck[i] = deck[j];
            deck[j] = temp;
        }
    }

    function resetDeck() public onlyOwner {
        delete deck;
        for (uint8 suit = 0; suit < 4; suit++) {
            for (uint8 value = 0; value < 13; value++) {
                deck.push(Card(Suit(suit), Value(value)));
            }
        }
        shuffleDeck();
        emit DeckReset();
    }
    function initializeDeck() public onlyOwner {
        delete deck;
        for (uint8 suit = 0; suit < 4; suit++) {
            for (uint8 value = 0; value < 13; value++) {
                deck.push(Card(Suit(suit), Value(value)));
            }
        }
        requestRandomNumber();
        shuffleDeck();
    }

    function dealCardsToPlayers(address[] memory _players) internal onlyOwner {
        require(deck.length >= _players.length * 2, "Not enough cards in deck");
        for (uint256 i = 0; i < _players.length; i++) {
            Card[] storage playerHand = playerHands[_players[i]];
            playerHand.push(deck[deck.length-1]);
            playerHand.push(deck[deck.length-2]);
            deck.pop();
            deck.pop();
            emit CardsDealt(_players[i], playerHands[_players[i]]);
        }
    }

    function dealCommunityCards(uint256 count) internal onlyOwner {
        require(deck.length >= count, "Not enough cards in deck");
        for(uint256 i = 0 ; i < count ; i ++) {
            communityCards.push(deck[deck.length-1]);
            deck.pop();
        }
        emit CommunityCardsDealt(communityCards);
    }

    function determineWinners() internal {
        address[] memory activePlayers = new address[](playersList.length);
        uint256[] memory handValues = new uint256[](playersList.length);
        uint256 activeCount = 0;

        for (uint256 i = 0; i < playersList.length; i++) {
            address player = playersList[i];
            if (players[player].isActive) {
                Card[] memory playerCards = playerHands[player];
                Card[] memory allCards = new Card[](playerCards.length + communityCards.length);
                
                for (uint256 j = 0; j < playerCards.length; j++) {
                    allCards[j] = playerCards[j];
                }
                
                for (uint256 k = 0; k < communityCards.length; k++) {
                    allCards[playerCards.length + k] = communityCards[k];
                }

                uint256 handValue = cardManagement.evaluateHand(allCards);
                handValues[activeCount] = handValue;
                activePlayers[activeCount] = player;
                activeCount++;
            }
        }

        uint256 winningValue = 0;
        address[] memory winners = new address[](activeCount);
        uint256 winnerCount = 0;

        for (uint256 i = 0; i < activeCount; i++) {
            if (handValues[i] > winningValue) {
                winningValue = handValues[i];
                winnerCount = 1;
                winners[0] = activePlayers[i];
            } else if (handValues[i] == winningValue) {
                winners[winnerCount] = activePlayers[i];
                winnerCount++;
            }
        }

        address[] memory actualWinners = new address[](winnerCount);
        for (uint256 i = 0; i < winnerCount; i++) {
            actualWinners[i] = winners[i];
        }

        distributePots();
        emit GameEnded();
    }

    function resetBettingRound() internal {
        currentBet = 0;
        for (uint256 i = 0; i < playersList.length; i++) {
            players[playersList[i]].hasActed = false;
        }
    }

    function playerAction(PlayerAction action, uint256 amount) external onlyCurrentPlayer inGameState(GameState.PreFlop) {
        require(amount >= minimumBet, "Bet amount below minimum");

        Player storage player = players[msg.sender];
        if (action == PlayerAction.Fold) {
            player.isActive = false;
            player.action = PlayerAction.Fold;
        } else if (action == PlayerAction.Check) {
            player.action = PlayerAction.Check;
        } else if (action == PlayerAction.Call) {
            uint256 callAmount = currentBet - player.currentBet;
            require(player.balance >= callAmount, "Poler Game : Insufficient balance to call");
            player.balance -= callAmount;
            player.currentBet = currentBet;
            player.action = PlayerAction.Call;
        } else if (action == PlayerAction.Bet || action == PlayerAction.Raise) {
            require(player.balance >= amount, "Poker Game : Insufficient balance to bet/raise");
            if (action == PlayerAction.Raise) {
                currentBet += amount;
            }
            player.balance -= amount;
            player.currentBet = currentBet;
            player.action = action;
        } else if (action == PlayerAction.AllIn) {
            player.currentBet = player.balance;
            player.balance = 0;
            player.action = PlayerAction.AllIn;
        } else {
            revert("Invalid action");
        }

        player.hasActed = true;

        currentPlayerIndex = (currentPlayerIndex + 1) % playersList.length;
        emit PlayerActionTaken(msg.sender, action, amount);

        if (allPlayersActed()) {
            nextGameState();
        }
    }

    function allPlayersActed() internal view returns (bool) {
        for (uint256 i = 0; i < playersList.length; i++) {
            if (players[playersList[i]].isActive && !players[playersList[i]].hasActed) {
                return false;
            }
        }
        return true;
    }

    function initializePots() internal {
        delete pots;
    }

    function createPot(uint256 amount, address[] memory eligiblePlayers) internal {
        pots.push(Pot({
            amount: amount,
            eligiblePlayers: eligiblePlayers
        }));

        emit PotCreated(pots.length - 1, amount, eligiblePlayers);
    }

    function distributePots() internal {        //need to fix
        for (uint256 i = 0; i < pots.length; i++) {
            Pot storage pot = pots[i];
            uint256 share = pot.amount / pot.eligiblePlayers.length;

            for (uint256 j = 0; j < pot.eligiblePlayers.length; j++) {
                address winner = pot.eligiblePlayers[j];
                userManagement.updateBalance(winner, share);
            }

            emit PotDistributed(i, pot.amount, pot.eligiblePlayers);
        }
    }

    function resetGame() external onlyOwner inGameState(GameState.Finished) {
        for (uint256 i = 0; i < playersList.length; i++) {
            address playerAddr = playersList[i];
            Player storage player = players[playerAddr];
            player.currentBet = 0;
            player.action = PlayerAction.None;
            player.isActive = true;
            player.hasActed = false;
        }

        delete pots;
        initializePots();

        dealerIndex = (dealerIndex + 1) % playersList.length;
        currentPlayerIndex = (dealerIndex + 1) % playersList.length;

        resetDeck();
        initializeDeck();

        gameState = GameState.PreFlop;
        dealCardsToPlayers(playersList);

        emit GameStateChanged(gameState);
    }

    function nextGameState() internal {
        if (gameState == GameState.PreFlop) {
            gameState = GameState.Flop;
            dealCommunityCards(3);
        } else if (gameState == GameState.Flop) {
            gameState = GameState.Turn;
            dealCommunityCards(1);
        } else if (gameState == GameState.Turn) {
            gameState = GameState.River;
            dealCommunityCards(1);
        } else if (gameState == GameState.River) {
            gameState = GameState.Showdown;
            determineWinners();
            gameState = GameState.Finished;
            updatePlayersInfo();
            
            bool updateAvailable = roomManagement.isUpdateAvailable(roomId);
            if(updateAvailable) syncPlayers();
        } else {
            revert("Invalid game state transition");
        }

        resetBettingRound();
        emit GameStateChanged(gameState);
    }

    function leaveGame() external {
        require(players[msg.sender].addr == msg.sender, "Poker Game : Player is not in the game");
        if(gameState == GameState.WaitingForPlayers) {
            roomManagement.removePlayer(roomId, msg.sender);
            userManagement.updateBalance(msg.sender, players[msg.sender].balance);
            emit PlayerLeft(msg.sender);
        }
        else {
            leavePlayersList.push(msg.sender);
        }
    }

    function getLeavePlayersList() external view returns (address[] memory) {
        return leavePlayersList;
    }

    function syncPlayers() internal {
        delete playersList;
        address[] memory _playerAddresses = roomManagement.getPlayers(roomId);
        for(uint i = 0; i < _playerAddresses.length; i++)
        {
            (string memory nickname, uint256 balance) = roomManagement.getPlayerInfo(roomId, _playerAddresses[i]);
            Player memory _newPlayer = Player(
                _playerAddresses[i],
                nickname,
                balance,
                0,
                PlayerAction.None,
                true,
                false
            );
            players[_playerAddresses[i]] = _newPlayer;
            playersList.push(_playerAddresses[i]);
        }
        emit PlayerListSyncFinished();
    }

    function updatePlayersInfo() internal {
        for(uint256 i = 0; i < leavePlayersList.length; i++) {
            for(uint256 j = 0; j < playersList.length; j++) {
                if(playersList[j] == leavePlayersList[i]) {
                    playersList[j] = playersList[playersList.length - 1];
                    playersList.pop();
                    roomManagement.removePlayer(roomId, leavePlayersList[i]);
                }
            }
            userManagement.updateBalance(leavePlayersList[i], players[leavePlayersList[i]].balance);
        }
        emit PlayersLeft(leavePlayersList);
        delete leavePlayersList;

        for(uint256 i = 0; i < playersList.length; i++)
        {
            roomManagement.updatePlayerInfo(
                roomId, 
                playersList[i], 
                players[playersList[i]].nickname,
                players[playersList[i]].balance
            );
        }
        emit PlayersInfoUpdated();
    }
}
