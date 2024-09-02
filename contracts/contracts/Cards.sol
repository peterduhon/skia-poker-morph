// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CardManagement
 * @dev This contract manages card-related operations, including hand evaluations for poker games.
 */
contract CardManagement is Ownable {
    
    enum Suit { Spades, Hearts, Diamonds, Clubs }
    enum Value { Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace }

    struct Card {
        Suit suit;
        Value value;
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

    /**
     * @dev Checks if the hand contains a pair.
     * @param hand The array of cards to evaluate.
     * @return True if the hand contains exactly one pair, false otherwise.
     */
    function isPair(Card[] memory hand) internal pure returns (bool) {
        return countValueOccurrences(hand, 2) == 1;
    }

    /**
     * @dev Checks if the hand contains three of a kind.
     * @param hand The array of cards to evaluate.
     * @return True if the hand contains exactly three of a kind, false otherwise.
     */
    function isThreeOfAKind(Card[] memory hand) internal pure returns (bool) {
        return countValueOccurrences(hand, 3) == 1;
    }

    /**
     * @dev Checks if the hand contains four of a kind.
     * @param hand The array of cards to evaluate.
     * @return True if the hand contains exactly four of a kind, false otherwise.
     */
    function isFourOfAKind(Card[] memory hand) internal pure returns (bool) {
        return countValueOccurrences(hand, 4) == 1;
    }

    /**
     * @dev Checks if the hand is a full house.
     * @param hand The array of cards to evaluate.
     * @return True if the hand is a full house, false otherwise.
     */
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

    /**
     * @dev Checks if the hand contains two pairs.
     * @param hand The array of cards to evaluate.
     * @return True if the hand contains exactly two pairs, false otherwise.
     */
    function isTwoPairs(Card[] memory hand) internal pure returns (bool) {
        return countValueOccurrences(hand, 2) == 2;
    }

    /**
     * @dev Checks if the hand is a straight.
     * @param hand The array of cards to evaluate.
     * @return True if the hand is a straight, false otherwise.
     */
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

    /**
     * @dev Checks if the hand is a flush.
     * @param hand The array of cards to evaluate.
     * @return True if the hand is a flush, false otherwise.
     */
    function isFlush(Card[] memory hand) internal pure returns (bool) {
        return countSuitOccurrences(hand, 5);
    }

    /**
     * @dev Checks if the hand is a straight flush.
     * @param hand The array of cards to evaluate.
     * @return True if the hand is a straight flush, false otherwise.
     */
    function isStraightFlush(Card[] memory hand) internal pure returns (bool) {
        return isFlush(hand) && isStraight(hand);
    }

    /**
     * @dev Checks if the hand is a royal flush.
     * @param hand The array of cards to evaluate.
     * @return True if the hand is a royal flush, false otherwise.
     */
    function isRoyalFlush(Card[] memory hand) internal pure returns (bool) {
        uint8[13] memory values;
        uint8[4] memory suits;
        for (uint i = 0; i < hand.length; i++) {
            suits[uint8(hand[i].suit)]++;
            values[uint8(hand[i].value)]++;
        }
        return (suits[0] >= 5 && values[9] == 1 && values[10] == 1 && values[11] == 1 && values[12] == 1);
    }

    /**
     * @dev Counts occurrences of a given value in the hand.
     * @param hand The array of cards to evaluate.
     * @param occurrence The number of occurrences to count.
     * @return The count of values with the given occurrence.
     */
    function countValueOccurrences(Card[] memory hand, uint8 occurrence) internal pure returns (uint8) {
        uint8[13] memory values;
        uint8 count = 0;
        for (uint8 i = 0; i < hand.length; i++) {
            values[uint8(hand[i].value)]++;
            if (values[uint8(hand[i].value)] == occurrence) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Checks if any suit has the given number of occurrences in the hand.
     * @param hand The array of cards to evaluate.
     * @param occurrence The number of occurrences to check for.
     * @return True if any suit has the given number of occurrences, false otherwise.
     */
    function countSuitOccurrences(Card[] memory hand, uint8 occurrence) internal pure returns (bool) {
        uint8[4] memory suits;
        for (uint8 i = 0; i < hand.length; i++) {
            suits[uint8(hand[i].suit)]++;
            if (suits[uint8(hand[i].suit)] == occurrence) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Gets the value of four of a kind from the hand.
     * @param hand The array of cards to evaluate.
     * @return The value of the four of a kind.
     * @notice Reverts if no four of a kind is found.
     */
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
        revert("Poker Game : No Four of a Kind found");
    }

    /**
     * @dev Gets the value of a full house from the hand.
     * @param hand The array of cards to evaluate.
     * @return The value of the full house encoded as ThreeOfAKindValue * 100 + PairValue.
     * @notice Reverts if no full house is found.
     */
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
        revert("Poker Game : No Full House found");
    }

    /**
     * @dev Gets the value of three of a kind from the hand.
     * @param hand The array of cards to evaluate.
     * @return The value of the three of a kind.
     * @notice Reverts if no three of a kind is found.
     */
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
        revert("Poker Game : No Three of a Kind found");
    }

    /**
     * @dev Gets the values of two pairs from the hand.
     * @param hand The array of cards to evaluate.
     * @return The values of the two pairs encoded as FirstPairValue * 100 + SecondPairValue.
     * @notice Reverts if no two pairs are found.
     */
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
        revert("Poker Game : No Two Pairs found");
    }

    /**
     * @dev Gets the value of a straight from the hand.
     * @param hand The array of cards to evaluate.
     * @return The highest value in the straight.
     * @notice Reverts if no straight is found.
     */
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
        revert("Poker Game : No Straight found");
    }

    /**
     * @dev Gets the suit value of a flush from the hand.
     * @param hand The array of cards to evaluate.
     * @return The suit value of the flush.
     * @notice Reverts if no flush is found.
     */
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
        revert("Poker Game : No Flush found");
    }

    /**
     * @dev Gets the value of a straight flush from the hand.
     * @param hand The array of cards to evaluate.
     * @return The highest value in the straight flush.
     * @notice Reverts if no straight flush is found.
     */
    function getStraightFlushValue(Card[] memory hand) internal pure returns (uint256) {
        if (isFlush(hand) && isStraight(hand)) {
            return getStraightValue(hand);
        }
        revert("Poker Game : No Straight Flush found");
    }

    /**
     * @dev Evaluates the hand and returns its ranking.
     * @param hand The array of cards to evaluate.
     * @return The hand ranking according to poker rules.
     */
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
}
