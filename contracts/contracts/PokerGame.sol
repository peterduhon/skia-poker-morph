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
    uint256 public currentBet;
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
    enum PlayerAction { Begin, Fold, Raise, Call, Check, AllIn }
    enum GamePhase { PreFlop, Flop, Turn, River, Showdown }

    GamePhase public currentPhase;
    Card[5] public communityCards;
    uint256 public communityCardCount;

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
        PlayerAction action;
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
    struct SidePot {
        uint256 amount;
        address[] eligiblePlayers;
    }
    uint256 public mainPot;
    SidePot[] public sidePots;

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
    event GameEnded(address[] winner);
    event GamePhaseAdvanced(GamePhase newPhase);
    
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

    modifier isActivePlayer(address player) {
        require(players[player].action != PlayerAction.Fold, "Poker Game : Player has folded.");
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
        players[msg.sender].action = PlayerAction.Begin;
        players[msg.sender].isAllIn = false;

        playerAddresses.push(msg.sender);
        emit PlayerRegistered(msg.sender);
    }

    // Start the Game
    function startGame() external onlyOwner {
        require(!gameActive, "PokerGame: Game is already in progress");
        require(playerAddresses.length > 1, "PokerGame: Not enough players to start the game");
        
        gameActive = true;
        currentBet = 0;
        currentPlayerIndex = 0;
        currentPhase = GamePhase.PreFlop;
        communityCardCount = 0;

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
            currentBet += buyInAmount;
        }
    }

   function resetRound() internal {
        currentRound.betAmount = 0;
        currentRound.totalPot = 0;
        delete currentRound.activePlayers;
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            players[playerAddresses[i]].action = PlayerAction.Begin;
        }
    }
    
    function endCurrentRound() internal onlyOwner isGameActive {
        require(currentRound.activePlayers.length > 1, "PokerGame: Not enough players to continue.");

        address[] memory activePlayers = currentRound.activePlayers;

        if (activePlayers.length == 1) {
            address winner = activePlayers[0];
            players[winner].balance += currentRound.totalPot;
            emit WinnerDeclared(winner);
            gameActive = false;
        } else {
            mainPot += currentRound.totalPot;
        }

        resetRound();
        emit RoundEnded(roundNumber);
        roundNumber++;
    }

    function advancePhase() external onlyOwner {
        require(currentPhase != GamePhase.Showdown, "Poker Game : Game is already in showdown phase");

        if (currentPhase == GamePhase.PreFlop) {
            currentPhase = GamePhase.Flop;
            dealCommunityCards(3);
        } else if (currentPhase == GamePhase.Flop) {
            currentPhase = GamePhase.Turn;
            dealCommunityCards(1);
        } else if (currentPhase == GamePhase.Turn) {
            currentPhase = GamePhase.River;
            dealCommunityCards(1);
        } else if (currentPhase == GamePhase.River) {
            currentPhase = GamePhase.Showdown;
        }

        emit GamePhaseAdvanced(currentPhase);
        // Reset betting for the new phase
        resetBettingRound();
    }

    // Manage Player's Turn with Validation
    function manageTurn(uint256 betAmount) external isGameActive isPlayer nonReentrant {
        require(msg.sender == playerAddresses[currentPlayerIndex], "PokerGame: Not your turn to play");
        
        Player storage player = players[msg.sender];

        require(player.action != PlayerAction.Fold, "PokerGame: Player has already folded");

        if (betAmount == 0) {
            player.action = PlayerAction.Check;
            // Proceed to the next player
        } else if (betAmount == currentRound.betAmount) {
            player.action = PlayerAction.Call;
            call();
        } else if (betAmount > currentRound.betAmount) {
            player.action = PlayerAction.Raise;
            raise(betAmount);
        } else {
            revert("PokerGame: Invalid bet amount");
        }

        emit TurnManaged(msg.sender);
        nextPlayerTurn();
    }

    // Check if the round is over
    function isRoundOver() internal view returns (bool) {
        for (uint256 i = 0; i < currentRound.activePlayers.length; i++) {
            if (players[currentRound.activePlayers[i]].action != PlayerAction.Fold) {
                return false;
            }
        }
        return true;
    }
 
    // Move to the next player's turn
    function nextPlayerTurn() internal {
        if (currentRound.activePlayers.length == 0) {
            return; // No players in the game
        }

        uint256 startIndex = currentPlayerIndex;
        do {
            currentPlayerIndex = (currentPlayerIndex + 1) % playerAddresses.length;
        } while (players[playerAddresses[currentPlayerIndex]].action == PlayerAction.Fold && currentPlayerIndex != startIndex);
        
        // If all players have folded or only one player remains, end the round
        if (currentRound.activePlayers.length == 1 || isRoundOver()) {
            endCurrentRound();
        }
    }

    // Place a bet
    function placeBet(uint256 amount) public isGameActive isPlayer nonReentrant {
        require(amount >= currentRound.betAmount, "PokerGame: Bet amount too low");
        require(players[msg.sender].balance >= amount, "PokerGame: Player doesn't have sufficient balance");

        players[msg.sender].balance -= amount;
        currentRound.playerBets[msg.sender] += amount;
        currentRound.totalPot += amount;

        emit PlayerBetPlaced(msg.sender, amount);
    }

    // Fold the current player's hand
    function fold() public isGameActive isPlayer nonReentrant {
        Player storage player = players[msg.sender];
        require(player.action != PlayerAction.Fold, "PokerGame: Player has already folded");
        
        player.action = PlayerAction.Fold;
        removePlayerFromActiveList(msg.sender);

        emit PlayerFolded(msg.sender);
        nextPlayerTurn();
    }

    // Call the current bet amount
    function call() internal {
        uint256 callAmount = currentRound.betAmount - currentRound.playerBets[msg.sender];
        require(players[msg.sender].balance >= callAmount, "PokerGame: Insufficient balance to call");

        players[msg.sender].balance -= callAmount;
        currentRound.playerBets[msg.sender] += callAmount;
        currentRound.totalPot += callAmount;

        emit PlayerCalled(msg.sender);
    }

    // Raise the current bet amount
    function raise(uint256 amount) internal {
        require(amount > currentRound.betAmount, "PokerGame: Raise amount too low");
        uint256 raiseAmount = amount - currentRound.betAmount;
        require(players[msg.sender].balance >= raiseAmount, "PokerGame: Insufficient balance to raise");

        players[msg.sender].balance -= raiseAmount;
        currentRound.playerBets[msg.sender] += raiseAmount;
        currentRound.totalPot += raiseAmount;
        currentRound.betAmount = amount;

        emit PlayerRaised(msg.sender, raiseAmount);
    }

    function handleAllIn(address player, uint256 allInAmount) internal {
        // If player's all-in amount is less than the current bet, create a side pot
        address[] memory activePlayers = currentRound.activePlayers;

        if (allInAmount < currentBet) {
            SidePot memory newSidePot;
            uint index = 0;
            newSidePot.amount = (currentBet - allInAmount) * (activePlayers.length - 1);
            for (uint i = 0; i < activePlayers.length; i++) {
                if (activePlayers[i] != player) {
                    newSidePot.eligiblePlayers[index++] = activePlayers[i];
                }
            }
            sidePots.push(newSidePot);
        }
        // Update main pot and player status
        mainPot += allInAmount;
        players[player].action = PlayerAction.AllIn;
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

    function endGame() external onlyOwner isGameActive {
        require(playerAddresses.length > 1, "PokerGame: Not enough players to end the game.");

        // Determine the winning players
        address[] memory winners = determineWinners();
        
        // Split the main pot among all winners
        uint256 winningAmount = mainPot / winners.length;
        for (uint256 i = 0; i < winners.length; i++) {
            payable(winners[i]).transfer(winningAmount);
        }

        // Distribute side pots if any
        for (uint256 i = 0; i < sidePots.length; i++) {
            address[] memory sideWinners = determineWinnersForSidePot(sidePots[i].eligiblePlayers);
            uint256 sideWinningAmount = sidePots[i].amount / sideWinners.length;
            for (uint256 j = 0; j < sideWinners.length; j++) {
                payable(sideWinners[j]).transfer(sideWinningAmount);
            }
        }
        
        // Reset game state
        delete communityCards;
        communityCardCount = 0;
        mainPot = 0;
        delete sidePots;
        currentPhase = GamePhase.PreFlop;
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            players[playerAddresses[i]].action = PlayerAction.Begin;
        }
        
        emit GameEnded(winners);
    }

    function determineWinners() internal view returns (address[] memory) {
        uint256 bestHandValue = 0;
        uint256 winnerCount = 0;
        
        // First pass: Find the best hand value
        for (uint i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            if (players[player].action != PlayerAction.Fold) {
                Card[] memory fullHand;
                fullHand[0] = players[player].hand[0];
                fullHand[1] = players[player].hand[1];
                for (uint j = 0; j < 5; j++) {
                    fullHand[j + 2] = communityCards[j];
                }

                uint256 handValue = evaluateHand(fullHand);
                if (handValue > bestHandValue) {
                    bestHandValue = handValue;
                    winnerCount = 1;
                } else if (handValue == bestHandValue) {
                    winnerCount++;
                }
            }
        }
        
        // Second pass: Collect all players with the best hand
        address[] memory winners = new address[](winnerCount);
        uint256 index = 0;
        for (uint i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            if (players[player].action != PlayerAction.Fold) {
                Card[] memory fullHand;
                fullHand[0] = players[player].hand[0];
                fullHand[1] = players[player].hand[1];
                for (uint256 j = 0; j < 5; j++) {
                    fullHand[j + 2] = communityCards[j];
                }

                uint256 handValue = evaluateHand(fullHand);
                if (handValue == bestHandValue) {
                    winners[index] = player;
                    index++;
                }
            }
        }

        return winners;
    }

    function determineWinnersForSidePot(address[] memory eligiblePlayers) internal view returns (address[] memory) {
        uint256 bestHandValue = 0;
        uint256 winnerCount = 0;
        
        // First pass: Find the best hand value
        for (uint i = 0; i < eligiblePlayers.length; i++) {
            address player = eligiblePlayers[i];
            if (players[player].action != PlayerAction.Fold) {
                Card[] memory fullHand;
                fullHand[0] = players[player].hand[0];
                fullHand[1] = players[player].hand[1];
                for (uint256 j = 0; j < 5; j++) {
                    fullHand[j + 2] = communityCards[j];
                }

                uint256 handValue = evaluateHand(fullHand);
                if (handValue > bestHandValue) {
                    bestHandValue = handValue;
                    winnerCount = 1;
                } else if (handValue == bestHandValue) {
                    winnerCount++;
                }
            }
        }
        
        // Second pass: Collect all players with the best hand
        address[] memory winners = new address[](winnerCount);
        uint256 index = 0;
        for (uint256 i = 0; i < eligiblePlayers.length; i++) {
            address player = eligiblePlayers[i];
            if (players[player].action != PlayerAction.Fold) {
                Card[] memory fullHand;
                fullHand[0] = players[player].hand[0];
                fullHand[1] = players[player].hand[1];
                for (uint256 j = 0; j < 5; j++) {
                    fullHand[j + 2] = communityCards[j];
                }

                uint256 handValue = evaluateHand(fullHand);
                if (handValue == bestHandValue) {
                    winners[index] = player;
                    index++;
                }
            }
        }

        return winners;
    }

    function distributePots() internal {
        address[] memory mainWinners = determineWinners();
        uint256 mainPotShare = mainPot / mainWinners.length;

        // Distribute the main pot among all main winners
        for (uint i = 0; i < mainWinners.length; i++) {
            payable(mainWinners[i]).transfer(mainPotShare);
        }

        // Distribute each side pot among the respective side pot winners
        for (uint i = 0; i < sidePots.length; i++) {
            address[] memory sideWinners = determineWinnersForSidePot(sidePots[i].eligiblePlayers);
            uint256 sidePotShare = sidePots[i].amount / sideWinners.length;

            for (uint j = 0; j < sideWinners.length; j++) {
                payable(sideWinners[j]).transfer(sidePotShare);
            }
        }
    }

    // Shuffle deck using randomness
    function shuffleDeck(uint256 randomness) internal {
        for (uint256 i = deck.length - 1; i > 0; i--) {
            uint256 j = randomness % (i + 1);
            (deck[i], deck[j]) = (deck[j], deck[i]);
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (!pendingRequests[requestId] || !gameActive) {
            emit RandomnessFailed(requestId);
            return;
        }
        pendingRequests[requestId] = false; // Mark the request as fulfilled
        shuffleDeck(randomness);
        dealCardsToPlayers();
        emit RandomnessReceived(randomness);
    }
    
    function removeCardFromDeck() internal {
        for (uint256 i = 1; i < deck.length; i++) {
            deck[i - 1] = deck[i];
        }
        deck.pop();
    }

    function drawCard() internal returns (Card memory) {
        // Replace this with actual card drawing logic
        Card memory newCard = Card({
            suit: Suit(deck[0] / 13),
            value: Value(deck[0] % 13)
        });
        removeCardFromDeck();
        return newCard;
    }

    function dealCardsToPlayers() internal {
        require(deck.length >= playerAddresses.length * 2, "PokerGame: Not enough cards in the deck");
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            Player storage player = players[playerAddresses[i]];
            player.hand.push(Card({
                suit: Suit(deck[0] / 13),
                value: Value(deck[0] % 13)
            }));
            removeCardFromDeck();
            player.hand.push(Card({
                suit: Suit(deck[0] / 13),
                value: Value(deck[0] % 13)
            }));
            removeCardFromDeck();
            emit CardDealt(playerAddresses[i], player.hand[0]);
            emit CardDealt(playerAddresses[i], player.hand[1]);
        }
    }

    function resetBettingRound() internal {
        currentBet = 0; // Reset the current bet amount
        for (uint i = 0; i < playerAddresses.length; i++) {
            currentRound.playerBets[playerAddresses[i]] = 0; // Reset bets for each player
        }
        currentPlayerIndex = 0; // Start betting with the first player again
    }

    function getCommunityCards() external view returns (Card[] memory) {
        Card[] memory cards = new Card[](communityCardCount);
        for (uint256 i = 0; i < communityCardCount; i++) {
            cards[i] = communityCards[i];
        }
        return cards;
    }

    function dealCommunityCards(uint256 cardsToDeal) internal {
        require(currentPhase == GamePhase.Flop || currentPhase == GamePhase.Turn || currentPhase == GamePhase.River, "Poker Game : Invalid game phase for dealing community cards");

        for (uint256 i = 0; i < cardsToDeal; i++) {
            communityCards[communityCardCount] = drawCard();
            emit CardDealt(address(0), communityCards[communityCardCount]); // address(0) indicates it's a community card
            communityCardCount++;
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

    function isPair(Card[] memory hand) internal pure returns (bool) {
        return countValueOccurrences(hand, 2) == 1;
    }

    function isThreeOfAKind(Card[] memory hand) internal pure returns (bool) {
        return countValueOccurrences(hand, 3) == 1;
    }

    function isFourOfAKind(Card[] memory hand) internal pure returns (bool) {
        return countValueOccurrences(hand, 4) == 1;
    }

    function isFullHouse(Card[] memory hand) internal pure returns (bool) {
        uint8[13] memory values;
        for (uint i = 0; i < hand.length; i++) {
            values[uint8(hand[i].value)]++;
        }
        bool foundThreeOfAKind = false;
        bool foundPair = false;
        for (uint i = 0; i < 13; i++) {
            if (values[i] == 3) {
                foundThreeOfAKind = true;
            } else if (values[i] == 2) {
                foundPair = true;
            }
        }
        return foundThreeOfAKind && foundPair;
    }

    function isTwoPairs(Card[] memory hand) internal pure returns (bool) {
        return countValueOccurrences(hand, 2) == 2;
    }

    function isStraight(Card[] memory hand) internal pure returns (bool) {
        uint8[13] memory valueCounts;
        for (uint i = 0; i < hand.length; i++) {
            valueCounts[uint8(hand[i].value)]++;
        }
        uint8 consecutiveCount = 0;
        for (uint8 i = 0; i < 13; i++) {
            if (valueCounts[i] > 0) {
                consecutiveCount++;
                if (consecutiveCount == 5) return true;
            } else {
                consecutiveCount = 0;
            }
        }
        // Ace-low straight
        if (valueCounts[12] > 0 && valueCounts[0] > 0 && valueCounts[1] > 0 && valueCounts[2] > 0 && valueCounts[3] > 0) {
            return true;
        }
        return false;
    }

    function isFlush(Card[] memory hand) internal pure returns (bool) {
        return countSuitOccurrences(hand, 5);
    }

    function isStraightFlush(Card[] memory hand) internal pure returns (bool) {
        return isFlush(hand) && isStraight(hand);
    }

    function isRoyalFlush(Card[] memory hand) internal pure returns (bool) {
        uint8[13] memory values;
        uint8[4] memory suits;
        for (uint i = 0; i < hand.length; i++) {
            suits[uint8(hand[i].suit)]++;
            values[uint8(hand[i].value)]++;
        }
        return (suits[0] >= 5 && values[9] == 1 && values[10] == 1 && values[11] == 1 && values[12] == 1);
    }

    function countValueOccurrences(Card[] memory hand, uint8 occurrence) internal pure returns (uint8) {
        uint8[13] memory values;
        for (uint8 i = 0; i < hand.length; i++) {
            values[uint8(hand[i].value)]++;
        }
        uint8 count = 0;
        for (uint8 i = 0; i < 13; i++) {
            if (values[i] == occurrence) {
                count++;
            }
        }
        return count;
    }

    function countSuitOccurrences(Card[] memory hand, uint8 occurrence) internal pure returns (bool) {
        uint8[4] memory suits;
        for (uint8 i = 0; i < hand.length; i++) {
            suits[uint8(hand[i].suit)]++;
        }
        for (uint8 i = 0; i < 4; i++) {
            if (suits[i] >= occurrence) {
                return true;
            }
        }
        return false;
    }

    function getFourOfAKindValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[13] memory values;
        for (uint256 i = 0; i < hand.length; i++) {
            values[uint256(hand[i].value)]++;
        }
        for (uint256 i = 0; i < 13; i++) {
            if (values[i] == 4) {
                return i;
            }
        }
        revert("No Four of a Kind found");
    }

    function getFullHouseValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[13] memory values;
        uint256 threeOfAKindValue;
        uint256 pairValue;
        for (uint256 i = 0; i < hand.length; i++) {
            values[uint256(hand[i].value)]++;
        }
        for (uint256 i = 0; i < 13; i++) {
            if (values[i] == 3) {
                threeOfAKindValue = i;
            } else if (values[i] == 2) {
                pairValue = i;
            }
        }
        if (threeOfAKindValue != 0 && pairValue != 0) {
            return threeOfAKindValue * 100 + pairValue;
        }
        revert("No Full House found");
    }

    function getThreeOfAKindValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[13] memory values;
        for (uint256 i = 0; i < hand.length; i++) {
            values[uint256(hand[i].value)]++;
        }
        for (uint256 i = 0; i < 13; i++) {
            if (values[i] == 3) {
                return i;
            }
        }
        revert("No Three of a Kind found");
    }

    function getTwoPairsValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[13] memory values;
        uint256 firstPair;
        uint256 secondPair;
        uint256 kicker = 0;

        // Count the occurrences of each card value
        for (uint256 i = 0; i < hand.length; i++) {
            values[uint256(hand[i].value)]++;
        }

        // Find the two pairs
        for (uint256 i = 0; i < 13; i++) {
            if (values[i] == 2) {
                if (firstPair == 0) {
                    firstPair = i;
                } else {
                    secondPair = i;
                    break;
                }
            }
        }

        // If we have two pairs
        if (firstPair != 0 && secondPair != 0) {
            // Ensure that pairs are ordered from highest to lowest
            if (firstPair < secondPair) {
                (firstPair, secondPair) = (secondPair, firstPair);
            }

            // Find the kicker (the card not part of any pair)
            for (uint256 i = 0; i < hand.length; i++) {
                if (uint256(hand[i].value) != firstPair && uint256(hand[i].value) != secondPair) {
                    kicker = kicker < uint256(hand[i].value) ? uint256(hand[i].value) : kicker;
                }
            }

            return firstPair * 10000 + secondPair * 100 + kicker;
        }

        revert("No Two Pairs found");
    }

    function getStraightValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[13] memory values;
        for (uint256 i = 0; i < hand.length; i++) {
            values[uint256(hand[i].value)]++;
        }
        for (uint256 i = 0; i < 9; i++) {
            if (values[i] > 0 && values[i+1] > 0 && values[i+2] > 0 && values[i+3] > 0 && values[i+4] > 0) {
                return i + 4;
            }
        }
        // Special case for Ace-low straight
        if (values[12] > 0 && values[0] > 0 && values[1] > 0 && values[2] > 0 && values[3] > 0) {
            return 3; // 5 in Ace-low straight
        }
        revert("No Straight found");
    }

    function getFlushValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[13] memory values;
        uint256[4] memory suits;
        for (uint256 i = 0; i < hand.length; i++) {
            suits[uint256(hand[i].suit)]++;
            values[uint256(hand[i].value)]++;
        }
        uint256 highCard = 0;
        for (uint256 i = 0; i < 4; i++) {
            if (suits[i] >= 5) {
                for (uint256 j = 0; j < hand.length; j++) {
                    if (uint256(hand[j].suit) == i) {
                        highCard = highCard < uint256(hand[j].value) ? uint256(hand[j].value) : highCard;
                    }
                }
                return highCard;
            }
        }
        revert("No Flush found");
    }

    function getStraightFlushValue(Card[] memory hand) internal pure returns (uint256) {
        uint256 straightValue = getStraightValue(hand);
        uint256 flushValue = getFlushValue(hand);
        return straightValue > flushValue ? straightValue : flushValue;
    }

    function evaluateHand(Card[] memory hand) internal pure returns (uint256) {
        if (isRoyalFlush(hand)) return uint256(HandRanking.RoyalFlush);
        if (isStraightFlush(hand)) return uint256(HandRanking.StraightFlush);
        if (isFourOfAKind(hand)) return uint256(HandRanking.FourOfAKind) * 100 + getFourOfAKindValue(hand);
        if (isFullHouse(hand)) return uint256(HandRanking.FullHouse) * 100 + getFullHouseValue(hand);
        if (isFlush(hand)) return uint256(HandRanking.Flush) * 100 + getFlushValue(hand);
        if (isStraight(hand)) return uint256(HandRanking.Straight) * 100 + getStraightValue(hand);
        if (isThreeOfAKind(hand)) return uint256(HandRanking.ThreeOfAKind) * 100 + getThreeOfAKindValue(hand);
        if (isTwoPairs(hand)) return uint256(HandRanking.TwoPairs) * 10000 + getTwoPairsValue(hand);
        // Add handling for One Pair and High Card if needed
        return uint256(HandRanking.HighCard);
    }
}
