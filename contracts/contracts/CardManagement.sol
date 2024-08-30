// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";

contract CardManagement is Ownable, VRFConsumerBase {
    // Structs and variables
    struct Card {
        uint8 suit;
        uint8 value;
    }
    
    enum HandRanking {
        HighCard,
        OnePair,
        TwoPairs,
        ThreeOfAKind,
        Straight,
        Flush,
        FullHouse,
        FourOfAKind,
        StraightFlush,
        RoyalFlush
    }

    Card[] public deck;
    Card[] public communityCards;
    mapping(address => Card[]) public playerHands; // Mapping to store players' hands

    address private vrfCoordinatorAddress;
    address private linkTokenAddress;

    bytes32 private keyHash;
    uint256 private fee;

    uint256 public seed;

    // Events
    event DeckInitialized();
    event CardsDealtToPlayers();
    event CommunityCardsDealt();

    // Constructor
    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        vrfCoordinatorAddress = vrfCoordinator;
        linkTokenAddress = linkToken;
        keyHash = _keyHash;
        fee = _fee;
        
        // Initialize the deck
        initializeDeck();
    }

    // Deck Management
    function initializeDeck() internal {
        delete deck; // Clear the existing deck if any
        for (uint256 suit = 0; suit < 4; suit++) {
            for (uint256 value = 0; value < 13; value++) {
                deck.push(Card(uint8(suit), uint8(value)));
            }
        }
        emit DeckInitialized();
    }

    function shuffleDeck() internal {
        require(seed > 0, "Seed not set");
        for (uint i = 0; i < deck.length; i++) {
            uint256 j = uint256(keccak256(abi.encodePacked(seed, i))) % deck.length;
            Card memory temp = deck[i];
            deck[i] = deck[j];
            deck[j] = temp;
        }
    }

    function removeCardFromDeck(uint256 index) internal {
        require(index < deck.length, "Index out of bounds");
        deck[index] = deck[deck.length - 1];
        deck.pop();
    }

    function drawCard() internal returns (Card memory) {
        require(deck.length > 0, "No cards left in the deck");
        uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed))) % deck.length;
        Card memory drawnCard = deck[index];
        removeCardFromDeck(index);
        return drawnCard;
    }

    function dealCardsToPlayers(address[] memory players) internal {
        require(players.length > 0, "No players to deal cards to");
        for (uint256 i = 0; i < players.length; i++) {
            delete playerHands[players[i]];
            for (uint256 j = 0; j < 2; j++) {
                playerHands[players[i]].push(drawCard());
            }
        }
        emit CardsDealtToPlayers();
    }

    function getCommunityCards() external view returns (Card[] memory) {
        return communityCards;
    }

    function dealCommunityCards() external onlyOwner {
        require(communityCards.length == 0, "Community cards already dealt");
        // Deal 5 community cards in stages
        for (uint256 i = 0; i < 5; i++) {
            communityCards.push(drawCard());
        }
        emit CommunityCardsDealt();
    }

    // Hand Evaluation
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
            return threeOfAKindValue * 100 + pairValue; // Encoding Full House as ThreeOfAKindValue * 100 + PairValue
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
        uint256 firstPairValue;
        uint256 secondPairValue;
        for (uint256 i = 0; i < hand.length; i++) {
            values[uint256(hand[i].value)]++;
        }
        for (uint256 i = 0; i < 13; i++) {
            if (values[i] == 2) {
                if (firstPairValue == 0) {
                    firstPairValue = i;
                } else {
                    secondPairValue = i;
                }
            }
        }
        if (firstPairValue != 0 && secondPairValue != 0) {
            return firstPairValue * 100 + secondPairValue; // Encoding TwoPairs as FirstPairValue * 100 + SecondPairValue
        }
        revert("No Two Pairs found");
    }

    function getStraightValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[13] memory values;
        for (uint256 i = 0; i < hand.length; i++) {
            values[uint256(hand[i].value)]++;
        }
        uint256 consecutiveCount = 0;
        for (uint256 i = 0; i < 13; i++) {
            if (values[i] > 0) {
                consecutiveCount++;
                if (consecutiveCount == 5) {
                    return i; // Highest value in the Straight
                }
            } else {
                consecutiveCount = 0;
            }
        }
        // Ace-low straight
        if (values[12] > 0 && values[0] > 0 && values[1] > 0 && values[2] > 0 && values[3] > 0) {
            return 3; // Highest value in the Ace-low Straight
        }
        revert("No Straight found");
    }

    function getFlushValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[4] memory suits;
        uint256[13] memory values;
        for (uint256 i = 0; i < hand.length; i++) {
            suits[uint256(hand[i].suit)]++;
            values[uint256(hand[i].value)]++;
        }
        for (uint256 i = 0; i < 4; i++) {
            if (suits[i] >= 5) {
                return i; // Suit value of the Flush
            }
        }
        revert("No Flush found");
    }

    function getStraightFlushValue(Card[] memory hand) internal pure returns (uint256) {
        if (isFlush(hand) && isStraight(hand)) {
            return getStraightValue(hand);
        }
        revert("No Straight Flush found");
    }

    function evaluateHand(Card[] memory hand) internal pure returns (HandRanking) {
        if (isRoyalFlush(hand)) return HandRanking.RoyalFlush;
        if (isStraightFlush(hand)) return HandRanking.StraightFlush;
        if (isFourOfAKind(hand)) return HandRanking.FourOfAKind;
        if (isFullHouse(hand)) return HandRanking.FullHouse;
        if (isFlush(hand)) return HandRanking.Flush;
        if (isStraight(hand)) return HandRanking.Straight;
        if (isThreeOfAKind(hand)) return HandRanking.ThreeOfAKind;
        if (isTwoPairs(hand)) return HandRanking.TwoPairs;
        if (isPair(hand)) return HandRanking.OnePair;
        return HandRanking.HighCard;
    }

    // Chainlink VRF Functions
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        seed = randomness;
        shuffleDeck();
    }

    function requestRandomness() external onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        requestRandomness(keyHash, fee);
    }
}
