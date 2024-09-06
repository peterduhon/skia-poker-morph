// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";
import "./Cards.sol";
import "./Rooms.sol";
import "./Users.sol";
import "./Common.sol";
import "./AIPlayer.sol";

contract BettingAndPotManagement is Ownable, ReentrancyGuard, VRFConsumerBase {
    GameState public gameState;
    AIPlayerManagement public aiPlayerEngine;

    address public houseAccount;
    uint256 public houseBalance;

    uint256 public minimumBet;
    uint256 public currentBet;
    uint256 public dealerIndex;
    uint256 public currentPlayerIndex;

    address[] public playersList;
    address[] public leavePlayersList;
    Player AIPlayer;
    mapping(address => Player) public players;
    mapping(uint256 => Card[]) public playerHands;
    Card[] public communityCards;
    Card[] public deck;

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
    event PotDistributed(uint256 amount, address player);
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

    modifier onlyCurrentPlayer() {
        require(playersList[currentPlayerIndex] == msg.sender, "It's not your turn");
        _;
    }
    
    modifier onlyHouseOrOwner() {
        require(msg.sender == houseAccount || msg.sender == owner(), "Not authorized");
        _;
    }

    constructor(
        uint256 _roomId,
        address _houseAccount,
        address _cardManagementAddress,
        address _roomManagementAddress,
        address _userManagementAddress,
        address _aiPlayerManagementAddress,
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
        aiPlayerEngine = AIPlayerManagement(_aiPlayerManagementAddress);
        minimumBet = _minimumBet;
        gameState = GameState.WaitingForPlayers;

        AIPlayer = Player (
            _houseAccount,
            "Bot",
            _minimumBet,
            0,
            PlayerAction.None,
            true,
            false
        );
        
        houseAccount = _houseAccount;
        houseBalance = 1000000 ether;
        
        keyHash = _keyHash;
        fee = _fee;
    }

    function isAIPlayer(uint256 _id) internal view returns(bool) {
        return playersList[_id] == houseAccount;
    }
    function addAIPlayer() public {
        playersList.push(houseAccount);
        players[houseAccount] = AIPlayer;
    }
    function onlyPlayer(address _player) internal view returns (bool) {
        for(uint256 i =0 ; i < playersList.length ; i ++)
            if(playersList[i] == _player) return true;
        return false;
    }

    function drawChipsForAI() internal {
        for(uint256 i = 0 ; i < playersList.length ; i++) {
            if(isAIPlayer(i)) {
                require(houseBalance >= minimumBet, "Poker Game : Insufficient house balance");
                houseBalance -= minimumBet;
                players[playersList[i]].balance += minimumBet;
            }
        }
    }

    function returnChipsFromAI() internal {
        for(uint256 i = 0 ; i < playersList.length ; i++) {
            if(isAIPlayer(i)) {
                houseBalance += players[playersList[i]].balance;
                players[playersList[i]].balance = 0;
            }
        }
    }

    function addFundsToHouse() external payable onlyOwner {
        houseBalance += msg.value;
    }

    function withdrawFromHouse(address receiver, uint256 amount) external onlyHouseOrOwner {
        require(houseBalance >= amount, "Insufficient house balance");
        houseBalance -= amount;
        payable(receiver).transfer(amount);
    }

    function getOpponentHistory() internal view returns (PlayerAction[] memory) {
        // Implement the logic to get the history of opponent actions
        // For simplicity, we'll return an empty array for now
        return new PlayerAction[](0);
    }

    function handleAITurn() internal {
        Player storage player = players[playersList[currentPlayerIndex]];
        
        uint256 handStrength = uint256(keccak256(abi.encodePacked(playersList[currentPlayerIndex], block.timestamp))) % 101;
        PlayerAction[] memory opponentHistory = getOpponentHistory();

        (PlayerAction action, uint256 amount) = aiPlayerEngine.decideBettingAction(
            handStrength,
            0,
            currentPlayerIndex,
            currentBet,
            player.balance,
            opponentHistory
        );

        playerAction(action, amount);
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

    function dealCardsToPlayers() internal onlyOwner {
        require(deck.length >= playersList.length * 2, "Not enough cards in deck");
        for (uint256 i = 0; i < playersList.length; i++) {
            Card[] storage playerHand = playerHands[i];
            playerHand.push(deck[deck.length-1]);
            playerHand.push(deck[deck.length-2]);
            deck.pop();
            deck.pop();
            emit CardsDealt(playersList[i], playerHands[i]);
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

    function determineWinners(uint256 totalPot) internal {
        address[] memory activePlayers = new address[](playersList.length);
        uint256[] memory handValues = new uint256[](playersList.length);
        uint256 activeCount = 0;

        // Collect hands for active players and evaluate their hand values
        for (uint256 i = 0; i < playersList.length; i++) {
            if (players[playersList[i]].isActive) {
                // Merge player hand and community cards
                Card[] memory allCards = new Card[](playerHands[i].length + communityCards.length);
                for (uint256 j = 0; j < playerHands[i].length; j++) {
                    allCards[j] = playerHands[i][j];
                }
                for (uint256 k = 0; k < communityCards.length; k++) {
                    allCards[playerHands[i].length + k] = communityCards[k];
                }

                // Evaluate hand
                uint256 handValue = cardManagement.evaluateHand(allCards);
                handValues[activeCount] = handValue;
                activePlayers[activeCount] = playersList[i];
                activeCount++;
            }
        }

        // Determine the winning hand(s)
        uint256 highestHandValue = 0;
        address[] memory winners = new address[](activeCount);
        uint256 winnerCount = 0;

        // Compare hand values
        for (uint256 i = 0; i < activeCount; i++) {
            if (handValues[i] > highestHandValue) {
                highestHandValue = handValues[i];
                winnerCount = 1;
                winners[0] = activePlayers[i];
            } else if (handValues[i] == highestHandValue) {
                winners[winnerCount] = activePlayers[i];
                winnerCount++;
            }
        }

        // Sort winners by their bet amounts (for side pots)
        for (uint256 i = 0; i < winnerCount - 1; i++) {
            for (uint256 j = i + 1; j < winnerCount; j++) {
                if (players[winners[i]].currentBet > players[winners[j]].currentBet) {
                    address temp = winners[i];
                    winners[i] = winners[j];
                    winners[j] = temp;
                }
            }
        }

        // Distribute the pot among the winners
        for (uint256 i = 0; i < winnerCount; i++) {
            uint256 maxWinAmount = players[winners[i]].currentBet * activeCount;
            for (uint256 j = 0; j < activeCount; j++) {
                if(players[activePlayers[j]].currentBet <= players[winners[i]].currentBet) {
                    players[activePlayers[j]].isActive = false;
                    maxWinAmount -= players[winners[i]].currentBet - players[activePlayers[j]].currentBet;
                }
                else players[activePlayers[j]].currentBet -= players[winners[i]].currentBet;
            }
            uint256 availablePot = totalPot / winnerCount;
            uint256 finalPot = maxWinAmount < availablePot ? maxWinAmount : availablePot;
            players[winners[i]].balance += finalPot;
            players[winners[i]].isActive = false;  // Mark as inactive after winning
            totalPot -= finalPot;

        }

        // If there's remaining pot, re-run the function to handle side pots
        if (totalPot > 0) determineWinners(totalPot);
        else emit GameEnded();
    }

    function resetBettingRound() internal {
        currentBet = 0;
        for (uint256 i = 0; i < playersList.length; i++) {
            players[playersList[i]].hasActed = false;
        }
    }

    function playerAction(PlayerAction action, uint256 amount) public onlyCurrentPlayer inGameState(GameState.PreFlop) {
        require(amount >= minimumBet, "Bet amount below minimum");

        Player storage player = players[msg.sender];
        if (action == PlayerAction.Fold) {
            player.action = PlayerAction.Fold;
            player.isActive = false;
        } else if (action == PlayerAction.Check) {
            require(player.currentBet == currentBet, "Poker Game: Cannot check, must call or raise.");
            player.action = PlayerAction.Check;
        } else if (action == PlayerAction.Call) {
            require(player.balance >= (currentBet - player.currentBet), "Poker Game: Insufficient balance to call.");
            uint256 callAmount = currentBet - player.currentBet;
            player.balance -= callAmount;
            player.currentBet = currentBet;
            player.action = PlayerAction.Call;
        } else if (action == PlayerAction.Bet) {
            // Ensure the bet is greater than the current bet (this is the first bet of the round)
            require(player.currentBet == currentBet, "Poker Game: Cannot bet, there is already a bet. Use raise instead.");
            require(player.balance >= amount, "Poker Game: Insufficient balance to bet.");
            currentBet += amount;
            player.balance -= amount;
            player.currentBet = currentBet;
            player.action = PlayerAction.Bet;
        } else if (action == PlayerAction.Raise) {
            // Ensure the raise is greater than the current bet
            require(player.balance >= amount, "Poker Game: Insufficient balance to raise.");
            require(amount > (currentBet - player.currentBet), "Poker Game: Raise must be greater than the current bet.");
            
            player.balance -= amount;
            player.currentBet += amount;
            currentBet = player.currentBet;
            player.action = PlayerAction.Raise;
        } else if (action == PlayerAction.AllIn) {
            // Player goes all-in with their full balance
            currentBet = player.balance > currentBet ? player.balance : currentBet;
            player.currentBet = player.balance;
            player.balance = 0;
            player.action = PlayerAction.AllIn;
        } else {
            revert("Poker Game: Invalid action.");
        }

        player.hasActed = true;

        currentPlayerIndex = (currentPlayerIndex + 1) % playersList.length;
        emit PlayerActionTaken(msg.sender, action, amount);

        if(isAIPlayer(currentPlayerIndex)) handleAITurn();

        if (allPlayersActed() && isAllSameBet()) {
            nextGameState();
        }
    }

    function isAllSameBet() internal view returns (bool) {
        for (uint256 i = 0; i < playersList.length; i++) {
            if (players[playersList[i]].isActive && players[playersList[i]].currentBet != currentBet) {
                if(players[playersList[i]].action != PlayerAction.AllIn) return false;
            }
        }
        return true;
    }

    function allPlayersActed() internal view returns (bool) {
        for (uint256 i = 0; i < playersList.length; i++) {
            if (players[playersList[i]].isActive && !players[playersList[i]].hasActed) {
                return false;
            }
        }
        return true;
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

        dealerIndex = (dealerIndex + 1) % playersList.length;
        currentPlayerIndex = (dealerIndex + 1) % playersList.length;

        resetDeck();
        initializeDeck();

        gameState = GameState.PreFlop;
        dealCardsToPlayers();

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
            uint256 totalPot = 0;
            for(uint256 i = 0 ; i < playersList.length; i++)
                totalPot += players[playersList[i]].currentBet;
            determineWinners(totalPot);
            gameState = GameState.Finished;
            bool updateAvailable = roomManagement.isUpdateAvailable(roomId);
            if(updateAvailable) syncPlayers();

            updatePlayersInfo();
            
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
        for(uint256 i = 0; i < playersList.length; i++) if(players[playersList[i]].balance == 0) {
            bool isExist = false;
            for(uint256 j = 0 ; j < leavePlayersList.length; j++)
                if(leavePlayersList[j] != playersList[i]) isExist = true;
            if(!isExist) leavePlayersList.push(playersList[i]);
        }

        for(uint256 i = 0; i < leavePlayersList.length; i++) {
            for(uint256 j = 0; j < playersList.length; j++) {
                if(playersList[j] == leavePlayersList[i]) {
                    playersList[j] = playersList[playersList.length - 1];
                    playersList.pop();
                    roomManagement.removePlayer(roomId, leavePlayersList[i]);
                    userManagement.userLeftRoom(leavePlayersList[i]);
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
        roomManagement.updatePlayersList(roomId, playersList);
        emit PlayersInfoUpdated();
    }

    function startGame() external onlyOwner inGameState(GameState.WaitingForPlayers) {
        syncPlayers();
        require(playersList.length > 1, "Not enough players to start the game"); // Ensure there are enough players to start the game
        // Shuffle and initialize the deck
        resetDeck();
        initializeDeck();

        // Reset game state and player information
        gameState = GameState.PreFlop;
        dealerIndex = 0;
        currentPlayerIndex = dealerIndex;
        currentBet = 0;

        // Deal initial cards to players
        dealCardsToPlayers();

        emit GameStarted(roomId);
        emit GameStateChanged(gameState);
    }

    function joinGame() external payable {
        require(gameState == GameState.WaitingForPlayers, "Game is not accepting new players");
        require(players[msg.sender].addr == address(0), "Player is already in the game"); // Ensure player is not already in the game
        require(msg.value >= minimumBet, "Insufficient chips sent to join the game");

        // Add the player to the game
        Player memory newPlayer = Player({
            addr: msg.sender,
            nickname: "Player",  // Default nickname, can be updated later
            balance: msg.value,
            currentBet: 0,
            action: PlayerAction.None,
            isActive: true,
            hasActed: false
        });

        players[msg.sender] = newPlayer;
        playersList.push(msg.sender);

        emit PlayerJoined(msg.sender);
    }

}
