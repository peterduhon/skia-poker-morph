// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Common.sol";

contract CardManagement is Ownable {

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

    function getHighValue(Card[] memory hand) internal pure returns (uint256) {
        uint256[13] memory values;
        for (uint256 i = 0; i < hand.length; i++) {
            values[uint256(hand[i].value)]++;
        }
        for (uint256 i = hand.length -1 ; i >= 0 ; i-- )
            if(values[i] > 0) return i;
    }

    function evaluateHand(Card[] memory hand) external pure returns (uint256) {
        if (isRoyalFlush(hand)) return uint256(HandRanking.RoyalFlush);
        if (isStraightFlush(hand)) return uint256(HandRanking.StraightFlush) * 1000000 + getStraightFlushValue(hand);
        if (isFourOfAKind(hand)) return uint256(HandRanking.FourOfAKind) * 1000000 + getFourOfAKindValue(hand);
        if (isFullHouse(hand)) return uint256(HandRanking.FullHouse) * 1000000 + getFullHouseValue(hand);
        if (isFlush(hand)) return uint256(HandRanking.Flush) * 1000000 + getFlushValue(hand);
        if (isStraight(hand)) return uint256(HandRanking.Straight) * 1000000 + getStraightValue(hand);
        if (isThreeOfAKind(hand)) return uint256(HandRanking.ThreeOfAKind) * 1000000 + getThreeOfAKindValue(hand);
        if (isTwoPairs(hand)) return uint256(HandRanking.TwoPairs) * 1000000 + getTwoPairsValue(hand);
        return getHighValue(hand);
    }

}
