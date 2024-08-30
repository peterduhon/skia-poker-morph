// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICardManagement {

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
    // Events
    event DeckInitialized();
    event CardsDealtToPlayers();
    event CommunityCardsDealt();

    // Deck Management
    function initializeDeck() external;
    function shuffleDeck() external;
    function removeCardFromDeck(uint256 index) external;
    function drawCard() external returns (Card memory);
    function dealCardsToPlayers(address[] memory players) external;
    function getCommunityCards() external view returns (Card[] memory);
    function dealCommunityCards() external;

    // Hand Evaluation
    function isPair(Card[] memory hand) external pure returns (bool);
    function isThreeOfAKind(Card[] memory hand) external pure returns (bool);
    function isFourOfAKind(Card[] memory hand) external pure returns (bool);
    function isFullHouse(Card[] memory hand) external pure returns (bool);
    function isTwoPairs(Card[] memory hand) external pure returns (bool);
    function isStraight(Card[] memory hand) external pure returns (bool);
    function isFlush(Card[] memory hand) external pure returns (bool);
    function isStraightFlush(Card[] memory hand) external pure returns (bool);
    function isRoyalFlush(Card[] memory hand) external pure returns (bool);
    function countValueOccurrences(Card[] memory hand, uint8 occurrence) external pure returns (uint8);
    function countSuitOccurrences(Card[] memory hand, uint8 occurrence) external pure returns (bool);
    function getFourOfAKindValue(Card[] memory hand) external pure returns (uint256);
    function getFullHouseValue(Card[] memory hand) external pure returns (uint256);
    function getThreeOfAKindValue(Card[] memory hand) external pure returns (uint256);
    function getTwoPairsValue(Card[] memory hand) external pure returns (uint256);
    function getStraightValue(Card[] memory hand) external pure returns (uint256);
    function getFlushValue(Card[] memory hand) external pure returns (uint256);
    function getStraightFlushValue(Card[] memory hand) external pure returns (uint256);
    function evaluateHand(Card[] memory hand) external pure returns (HandRanking);
}
