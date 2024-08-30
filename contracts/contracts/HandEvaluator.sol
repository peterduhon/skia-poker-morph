// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";


/// @title A contract for a poker game
/// @author James Wong
/// @notice This contract manages a poker game with multiple players
/// @dev All function calls are currently implemented without side effects

contract HandEvaluator is VRFConsumerBase  {
    // Chainlink VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;

    // Game state variables
    address public owner;
    uint256 public buyInAmount;
    uint256 public currentPot;
    uint256 public mainPot;
    bool public gameActive;
    uint256 public currentPlayerIndex;
    uint256[] public deck;
    uint256 public currentBet;
    enum PlayerAction { Begin, Fold, Raise, Call, Check, AllIn }
    GamePhase public currentPhase;
    Card[5] public communityCards;
    uint256 public communityCardCount;
    mapping(bytes32 => bool) public pendingRequests;
    uint256[52] private INITIAL_DECK = [
    0,1,2,3,4,5,6,7,8,9,10,11,12,
    13,14,15,16,17,18,19,20,21,22,23,24,25,
    26,27,28,29,30,31,32,33,34,35,36,37,38,
    39,40,41,42,43,44,45,46,47,48,49,50,51
];

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

    // Card suits and values using enums
    enum Suit { Spades, Hearts, Diamonds, Clubs }
    enum Value { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }
    enum GamePhase { PreFlop, Flop, Turn, River, Showdown }
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

    // Card structure using enums
    struct Card {
        Suit suit;
        Value value;
    }

    // Betting round data
    struct BettingRound {
        uint256 betAmount;        // Amount players need to match
        uint256 totalPot;         // Total pot for this round
        mapping(address => uint256) playerBets; // Mapping of player addresses to their bets
        address[] activePlayers;  // Players still active in this round
    }
    BettingRound public currentRound;
    uint256 public roundNumber;

    // Improved Betting Logic
    struct Pot {
        uint256 amount;
        address[] eligiblePlayers;
    }

    
    struct SidePot {
    uint256 amount;
    address[] eligiblePlayers;
}
SidePot[] public sidePots;

    
    // Events
    event PlayerRegistered(address indexed player);
    event CardDealt(address indexed player, Card card);
    event TurnManaged(address indexed player);
    event WinnerDeclared(address indexed winner);
    event RandomnessRequested(bytes32 requestId);
    event RandomnessFailed(bytes32 requestId);

    // New events
    event PlayerBetPlaced(address indexed player, uint256 amount);
    event PlayerCalled(address indexed player, uint amount);
    event PlayerRaised(address indexed player, uint256 amount);
    event PlayerFolded(address indexed player);
    event NewRoundStarted(uint256 roundNumber);
    event RoundEnded(uint256 roundNumber);
    event GameStarted();
    event GameEnded(address[] winner);
    event BetPlaced(address player, uint256 amount);
    event PayoutProcessed(address player, uint256 amout);

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

    // Modifiers for validation
    modifier onlyOwner() {
        require(msg.sender == owner, "PokerGame: Caller is not the contract owner");
        _;
    }

    modifier isGameActive() {
        require(gameActive, "PokerGame: A game is not active.");
        _;
    }

    modifier isPlayer() {
        require(players[msg.sender].registered, "PokerGame: Player is not registered");
        _;
    }

    modifier isEOA() {
        require(msg.sender.code.length == 0, "PokerGame: Only EOA can call this function");
        _;
    }

    modifier nonReentrant() {
        require(!reentrant, "PokerGame: Reentrancy detected");
        reentrant = true;
        _;
        reentrant = false;
    }

    bool private reentrant;  // State variable to track reentrancy

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
        require(playerAddresses.length >=2, "PokerGame: Not enough players to start the game");
        require(LINK.balanceOf(address(this)) >= fee, "PokerGame: Not enough LINK to request randomness");

        gameActive = true;
        currentPot = 0;
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
            currentPot += buyInAmount;
        }
    }

    // Manage Player's Turn with Validation
    function manageTurn(uint256 betAmount) external isGameActive isPlayer {

    require(msg.sender == playerAddresses[currentPlayerIndex], "PokerGame: It's not your turn to play. Please wait for your turn.");
    require(players[msg.sender].action != PlayerAction.Fold, "PokerGame: You have already folded and cannot take any more actions in this hand.");
    require(betAmount >= currentRound.betAmount || betAmount == 0, "PokerGame: Invalid bet amount");
    require(players[msg.sender].balance >= betAmount, "PokerGame: Insufficient balance");

        // Handle different actions
        if (betAmount == 0) {
            fold();
        } else if (betAmount == currentRound.betAmount) {
            call();
        } else if (betAmount > currentRound.betAmount) {
            raise(betAmount);
        } else {
            revert("PokerGame: Invalid bet amount");
        }

        emit TurnManaged(msg.sender);
        nextPlayerTurn();
    }

    function placeBet(uint256 amount) public isGameActive isPlayer {
        require(amount >= currentRound.betAmount, "PokerGame: Bet amount too low. Minimum bet: {currentRound.betAmount}, Your bet: {amount}");
    require(players[msg.sender].balance >= amount, "PokerGame: Insufficient balance. Required: {amount}, Your balance: {players[msg.sender].balance}");

        players[msg.sender].balance -= amount;
        currentRound.playerBets[msg.sender] += amount;
        currentRound.totalPot += amount;

        emit PlayerBetPlaced(msg.sender, amount);
    }

    function fold() internal {
        players[msg.sender].action = PlayerAction.Fold;
        removePlayerFromActiveList(msg.sender);
        emit PlayerFolded(msg.sender);

        if (getCurrentActivePlayers() == 1) {
            address[] memory lastActivePlayer;
            lastActivePlayer[0] = getLastActivePlayer();
         endGame(lastActivePlayer);
       }

    }

    function call() internal {
        uint256 callAmount = currentRound.betAmount - currentRound.playerBets[msg.sender];
        require(players[msg.sender].balance >= callAmount, "PokerGame: Insufficient balance to call");
        players[msg.sender].balance -= callAmount;
        currentRound.playerBets[msg.sender] += callAmount;
        currentRound.totalPot += callAmount;
        mainPot += callAmount;

        emit PlayerCalled(msg.sender, callAmount);

       if (isRoundComplete()) {
        advancePhase();
       }
    }

    function raise(uint256 amount) internal {
        require(amount > currentRound.betAmount, "PokerGame: Raise amount must be higher than current bet");
        uint256 raiseAmount = amount - currentRound.playerBets[msg.sender];
        require(players[msg.sender].balance >= raiseAmount, "PokerGame: Insufficient balance to raise");

       players[msg.sender].balance -= raiseAmount;
       currentRound.playerBets[msg.sender] += raiseAmount;
       currentRound.totalPot += raiseAmount;
      currentRound.betAmount = amount;
      mainPot += raiseAmount;

      emit PlayerRaised(msg.sender, raiseAmount);

      resetPlayersActed();

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

    function getCurrentActivePlayers() internal view returns (uint256) {
    uint256 activePlayers = 0;
    for (uint256 i = 0; i < playerAddresses.length; i++) {
    if (players[playerAddresses[i]].action != PlayerAction.Fold) {
    activePlayers++;
    }
    }
    return activePlayers;
    }

   function getLastActivePlayer() internal view returns (address) {
   for (uint256 i = 0; i < playerAddresses.length; i++) {
   if (players[playerAddresses[i]].action != PlayerAction.Fold) {
   return playerAddresses[i];
   }
   }
   revert("PokerGame: No active players found");
   }

function isRoundComplete() internal view returns (bool) {
for (uint256 i = 0; i < playerAddresses.length; i++) {
if (players[playerAddresses[i]].action != PlayerAction.Fold &&
currentRound.playerBets[playerAddresses[i]] < currentRound.betAmount) {
return false;
}
}
return true;
}

function resetPlayersActed() internal {
for (uint256 i = 0; i < playerAddresses.length; i++) {
if (players[playerAddresses[i]].action != PlayerAction.Fold) {
players[playerAddresses[i]].action = PlayerAction.Begin;
}
}
}

    function isOnePair(Card[] memory hand) internal pure returns (bool) {
    for (uint8 i = 0; i < hand.length - 1; i++) {
        for (uint8 j = i + 1; j < hand.length; j++) {
            if (hand[i].value == hand[j].value) {
                return true;
            }
        }
    }
    return false;
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
    // Check for Ace-low straight
    if (valueCounts[12] > 0 && valueCounts[0] > 0 && valueCounts[1] > 0 && valueCounts[2] > 0 && valueCounts[3] > 0) {
        return true;
    }
    return false;
}

function isFlush(Card[] memory hand) internal pure returns (bool) {
    uint8[4] memory suitCounts;
    for (uint8 i = 0; i < hand.length; i++) {
        suitCounts[uint8(hand[i].suit)]++;
        if (suitCounts[uint8(hand[i].suit)] == 5) {
            return true;
        }
    }
    return false;

}

function isRoyalFlush(Card[] memory hand)internal pure returns (bool){
    uint8[13] memory values;
        uint8[4] memory suits;
        for (uint i = 0; i < hand.length; i++) {
            suits[uint8(hand[i].suit)]++;
            values[uint8(hand[i].value)]++;
        }
        return (suits[0] >= 5 && values[9] == 1 && values[10] == 1 && values[11] == 1 && values[12] == 1);
}

function isStraightFlush(Card[] memory hand)internal pure returns (bool){
    Suit suit = hand[0].suit;
    uint8[] memory values = new uint8[](13);
    
    for (uint i = 1; i < 5; i++) {
        values[i] = uint8(hand[i].value);
        if (hand[i].suit != suit) {
            return false;
        }
    }

    uint8[13] memory valueCounts;
    for (uint8 i = 0; i < hand.length; i++) {
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
    return true;
}

function isFourOfAKind(Card[] memory hand)internal pure returns (bool){
uint8[4] memory valueCounts;
    for (uint8 i = 0; i < hand.length; i++) {
        valueCounts[uint8(hand[i].value)]++;
        if (valueCounts[uint8(hand[i].value)]==4){
            return true;
        }
    }
  
    return false;

}

function isFullHouse(Card[] memory hand)internal pure returns (bool){
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

function isThreeOfAKind(Card[] memory hand) public pure returns (bool) {
    
    uint8[4] memory valueCounts;
    for (uint8 i = 0; i < hand.length; i++) {
        valueCounts[uint8(hand[i].value)]++;
        if (valueCounts[uint8(hand[i].value)]==3){
            return true;
        }
    }
  
    return false;
}

function isTwoPairs(Card[] memory hand) public pure returns (bool) {
 uint8[13] memory values;
        for (uint8 i = 0; i < hand.length; i++) {
            values[uint8(hand[i].value)]++;
        }
        uint8 count = 0;
        for (uint8 i = 0; i < values.length; i++) {
            if (values[i] == 2) {
                count++;
            }
            if (count==2){
                return true;
            }
        }
        return false;
}

function getHighCard(Card[] memory hand) internal pure returns (uint256) {
    uint256 highCardValue = 0;
    for (uint256 i = 0; i < hand.length; i++) {
        if (uint256(hand[i].value) > highCardValue) {
            highCardValue = uint256(hand[i].value);
        }
    }
    return highCardValue;
}

function getHighCardValue(Card[] memory hand) internal pure returns (uint256) {
   uint256 value;
    assembly {
        let len := mload(hand)
        for { let i := 0 } lt(i, len) { i := add(i, 1) }
        {
            let card := mload(add(add(hand, 0x20), mul(i, 0x20)))
            value := add(mul(value, 13), mod(card, 13))
        }
    }
    return value;

}

function getPairValue(Card[] memory hand) internal pure returns (uint256) {
    uint256 pairValue = 0;
    uint256 highCards = 0;
    for (uint i = 0; i < hand.length - 1; i++) {
        for (uint j = i + 1; j < hand.length; j++) {
            if (hand[i].value == hand[j].value) {
                pairValue = uint256(hand[i].value);
                break;
            }
        }
        if (pairValue > 0) break;
    }
    for (uint8 i = 0; i < hand.length; i++) {
        if (uint256(hand[i].value) != pairValue) {
            highCards = highCards * 13 + uint256(hand[i].value);
        }
    }
    return pairValue * 1000000 + highCards;
}

function getFourOfAKindValue(Card[] memory hand) internal pure returns (uint256) {
    uint256 fourOfAKindValue = 0;
    uint256 kickerValue = 0;

    uint8[4] memory valueCounts;
    for (uint8 i = 0; i < hand.length; i++) {
        valueCounts[uint8(hand[i].value)]++;
        if (valueCounts[uint8(hand[i].value)]==4){
            fourOfAKindValue=uint8(hand[i].value);
        }
    }
       
            kickerValue = valueCounts[valueCounts.length -1];
            
       return fourOfAKindValue * 1000000 + kickerValue;
}

function getFullHouseValue(Card[] memory hand) internal pure returns (uint256) {
    uint256 threeOfAKindValue = 0;
    uint256 pairValue = 0;

    uint8[4] memory valueCounts;

    for (uint256 i = 0; i < hand.length; i++) {
        Value currentValue = hand[i].value;
        valueCounts[i]++;

        if (valueCounts[i] == 3) {
            threeOfAKindValue = uint256(currentValue);
        } else if (valueCounts[i] == 2) {
            pairValue = uint256(currentValue);
        }
    }

    return threeOfAKindValue * 1000000 + pairValue;
}

function getFlushValue(Card[] memory hand) internal pure returns (uint256) {
    uint256[5] memory flushValues;

      for (uint256 i = 0; i < hand.length; i++) {
        bool inserted = false;
        for (uint256 j = 0; j < 5; j++) {
            if (!inserted && uint256(hand[i].value) > flushValues[j]) {
                for (uint256 k = 4; k > j; k--) {
                    flushValues[k] = flushValues[k - 1];
                }
                flushValues[j] = uint256(hand[i].value);
                inserted = true;
                break;
            }
        }
        if (!inserted) {
            flushValues[4] = uint256(hand[i].value);
        }
    }

    // Calculate the flush value
    uint256 flushValue = 0;
    for (uint256 i = 0; i < 5; i++) {
        flushValue = flushValue * 13 + flushValues[i];
    }

    return flushValue;
}

function getStraightValue(Card[] memory hand) internal pure returns (uint256) {
    uint8[13] memory valueCounts;
    uint256 straightValue = 0;

        for (uint256 i = 0; i < hand.length; i++) {
        valueCounts[uint8(hand[i].value)]++;
    }

       for (uint8 i = 12; i >= 4; i--) {
        if (valueCounts[i] > 0) {
            bool straight = true;
            for (uint8 j = 0; j < 5; j++) {
                if (valueCounts[i - j] == 0) {
                    straight = false;
                    break;
                }
            }
            if (straight) {
                straightValue = i;
                break;
            }
        }
    }

       if (straightValue == 0) {
        if (valueCounts[0] > 0 && valueCounts[1] > 0 && valueCounts[2] > 0 && valueCounts[3] > 0 && valueCounts[12] > 0) {
            straightValue = 3;
        }
    }

    return straightValue;
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

     function distributePots() internal {
        require(currentPhase == GamePhase.Showdown, "PokerGame: Cannot distribute pots before showdown");

        // Distribute main pot
        address[] memory mainWinners = determineWinners();
        uint256 mainPotShare = mainPot / mainWinners.length;
        for (uint256 i = 0; i < mainWinners.length; i++) {
        players[mainWinners[i]].balance += mainPotShare;
        emit PayoutProcessed(mainWinners[i], mainPotShare);
}
// Distribute side pots
for (uint256 i = 0; i < sidePots.length; i++) {
    address[] memory sideWinners = determineWinnersForSidePot(sidePots[i].eligiblePlayers);
    uint256 sidePotShare = sidePots[i].amount / sideWinners.length;
    for (uint256 j = 0; j < sideWinners.length; j++) {
        players[sideWinners[j]].balance += sidePotShare;
        emit PayoutProcessed(sideWinners[j], sidePotShare);
    }
}

// Reset game state
resetGameState(mainWinners);
  }

  // Helper function to reset game state after pot distribution
function resetGameState(address[] memory winnersArray) internal {
gameActive = false;
mainPot = 0;
delete sidePots;
currentPhase = GamePhase.PreFlop;
communityCardCount = 0;
delete communityCards;

for (uint256 i = 0; i < playerAddresses.length; i++) {
    delete players[playerAddresses[i]].hand;
    players[playerAddresses[i]].action = PlayerAction.Begin;
    players[playerAddresses[i]].isAllIn = false;
}

emit GameEnded(winnersArray);
}


 function removePlayerFromActiveList(address player) internal {
        // Implementation to remove player from activePlayers array
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

    function endCurrentRound() external onlyOwner {
        // Logic to resolve betting round, determine actions, and prepare for the next round
        resetRound();
    }

    function resetRound() internal {
        // Reset currentRound state variables for the next round
        currentRound.betAmount = 0;
        currentRound.totalPot = 0;
        delete currentRound.activePlayers;
        emit RoundEnded(roundNumber);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (!pendingRequests[requestId] || !gameActive) {
            emit RandomnessFailed(requestId);
            return; // Request ID is not recognized or game is inactive
        }

        pendingRequests[requestId] = false; // Mark the request as fulfilled
        dealCards(randomness);
    }

    function dealCards(uint256 randomness) internal isGameActive {
        shuffleDeck(randomness);

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address player = playerAddresses[i];
            players[player].hand.push(drawCard());
            players[player].hand.push(drawCard()); // Dealing two cards per player
            emit CardDealt(player, players[player].hand[0]);
            emit CardDealt(player, players[player].hand[1]);
        }
    }

    function dealCommunityCards() internal {
     require(currentPhase != GamePhase.PreFlop && currentPhase != GamePhase.Showdown, 
        "PokerGame: Cannot deal community cards in PreFlop or Showdown phase. Current phase: {uint(currentPhase)}");
    
    uint256 cardsToDeal;
    if (currentPhase == GamePhase.Flop) {
        cardsToDeal = 3;
    } else {
        cardsToDeal = 1;
    }

    for (uint256 i = 0; i < cardsToDeal; i++) {
        communityCards[communityCardCount] = drawCard();
        emit CardDealt(address(0), communityCards[communityCardCount]); // address(0) indicates it's a community card
        communityCardCount++;
    }
}

function getCommunityCards() external view returns (Card[] memory) {
    Card[] memory cards = new Card[](communityCardCount);
    for (uint256 i = 0; i < communityCardCount; i++) {
        cards[i] = communityCards[i];
    }
    return cards;
}


function advancePhase() public onlyOwner {
    require(currentPhase != GamePhase.Showdown, "Game is already in showdown phase");
    
    if (currentPhase == GamePhase.PreFlop) {
        currentPhase = GamePhase.Flop;
        dealCommunityCards();
    } else if (currentPhase == GamePhase.Flop) {
        currentPhase = GamePhase.Turn;
        dealCommunityCards();
    } else if (currentPhase == GamePhase.Turn) {
        currentPhase = GamePhase.River;
        dealCommunityCards();
    } else if (currentPhase == GamePhase.River) {
        currentPhase = GamePhase.Showdown;
    }

    resetBettingRound();
}

function resetBettingRound() internal {
    currentBet = 0;
    for (uint256 i = 0; i < playerAddresses.length; i++) {
        currentRound.playerBets[playerAddresses[i]] = 0;
    }
    currentPlayerIndex = 0; 
}



    function drawCard() internal returns (Card memory) {
        uint256 cardIndex = deck[deck.length - 1];
        deck.pop();
        return Card(Suit(cardIndex / 13), Value(cardIndex % 13));
    }

    function shuffleDeck(uint256 randomness) internal {
    for (uint256 i = 51; i > 0; i--) {
        uint256 j = randomness % (i + 1);
        assembly {
            let ptr := deck.slot
            let iValue := sload(add(ptr, i))
            let jValue := sload(add(ptr, j))
            sstore(add(ptr, i), jValue)
            sstore(add(ptr, j), iValue)
        }
        randomness = uint256(keccak256(abi.encode(randomness)));
    }
}

    function initializeDeck() internal {
        deck = INITIAL_DECK;
    }

    function nextPlayerTurn() internal {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerAddresses.length;
    }

    function endGame(address[] memory winner) public onlyOwner {
        require(gameActive, "PokerGame: Game is not in progress");
        gameActive = false;
        delete communityCards;
        communityCardCount = 0;
        currentPhase = GamePhase.PreFlop;

        emit GameEnded(winner);
    }

    function evaluateHand(Card[] memory hand) internal pure returns (uint256) {
     require(hand.length == 7, "PokerGame: Invalid hand size. Expected 7 cards, got {hand.length}");

    if (isRoyalFlush(hand)) return uint256(HandRanking.RoyalFlush) * 1000000 + getHighCard(hand);
    if (isStraightFlush(hand)) return uint256(HandRanking.StraightFlush) * 1000000 + getHighCard(hand);
    if (isFourOfAKind(hand)) return uint256(HandRanking.FourOfAKind) * 1000000 + getFourOfAKindValue(hand);
    if (isFullHouse(hand)) return uint256(HandRanking.FullHouse) * 1000000 + getFullHouseValue(hand);
    if (isFlush(hand)) return uint256(HandRanking.Flush) * 1000000 + getFlushValue(hand);
    if (isStraight(hand)) return uint256(HandRanking.Straight) * 1000000 + getStraightValue(hand);
    if (isThreeOfAKind(hand)) return uint256(HandRanking.ThreeOfAKind) * 1000000 + getThreeOfAKindValue(hand);
    if (isTwoPairs(hand)) return uint256(HandRanking.TwoPairs) * 1000000 + getTwoPairsValue(hand);
    if (isOnePair(hand)) return uint256(HandRanking.Pair) * 1000000 + getPairValue(hand);
    
    return uint256(HandRanking.HighCard) * 1000000 + getHighCardValue(hand);

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

}