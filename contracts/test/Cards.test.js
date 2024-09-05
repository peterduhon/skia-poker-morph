const { expect } = require("chai");
const hre = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("CardManagement Contract", function () {
    let CardManagement;
    let cardManagement;

    beforeEach(async function () {
        CardManagement = await hre.ethers.getContractFactory("CardManagement");
        cardManagement = await CardManagement.deploy();
        await cardManagement.waitForDeployment();
    });

    function createCard(value, suit) {
        return { value, suit };
    }

    it("should correctly identify a Royal Flush", async function () {
        const hand = [
            createCard(8, 0), // 10 of Hearts
            createCard(9, 0), // Jack of Hearts
            createCard(10, 0), // Queen of Hearts
            createCard(11, 0), // King of Hearts
            createCard(12, 0),  // Ace of Hearts
            createCard(0, 1),  // 2 of Diamonds (not part of the flush)
            createCard(1, 2)   // 3 of Clubs (not part of the flush)
        ];

        const result = await cardManagement.evaluateHand(hand);
        expect(result).to.equal(9); // HandRanking.RoyalFlush
    });

    it("should correctly identify a Four of a Kind", async function () {
        const hand = [
            createCard(5, 0), // 7 of Hearts
            createCard(5, 1), // 7 of Diamonds
            createCard(5, 2), // 7 of Clubs
            createCard(5, 3), // 7 of Spades
            createCard(12, 0), // Ace of Hearts
            createCard(0, 1), // 2 of Diamonds
            createCard(1, 2)  // 3 of Clubs
        ];

        const result = await cardManagement.evaluateHand(hand);
        expect(result).to.equal(7 * 1000000 + 5); // HandRanking.FourOfAKind * 1000000 + Four of a Kind Value
    });

    it("should correctly identify a Full House", async function () {
        const hand = [
            createCard(3, 0), // 5 of Hearts
            createCard(3, 1), // 5 of Diamonds
            createCard(3, 2), // 5 of Clubs
            createCard(0, 3), // 2 of Spades
            createCard(0, 0), // 2 of Hearts
            createCard(1, 1), // 3 of Diamonds
            createCard(2, 2)  // 4 of Clubs
        ];

        const result = await cardManagement.evaluateHand(hand);
        expect(result).to.equal(6 * 1000000 + 401); // HandRanking.FullHouse * 1000000 + Full House Value
    });

    it("should correctly identify a Straight", async function () {
        const hand = [
            createCard(1, 0), // 3 of Hearts
            createCard(2, 1), // 4 of Diamonds
            createCard(3, 2), // 5 of Clubs
            createCard(4, 3), // 6 of Spades
            createCard(5, 0), // 7 of Hearts
            createCard(7, 1), // 9 of Diamonds (not part of the straight)
            createCard(8, 2) // 10 of Clubs (not part of the straight)
        ];

        const result = await cardManagement.evaluateHand(hand);
        expect(result).to.equal(4 * 1000000 + 5); // HandRanking.Straight * 1000000 + Straight Value
    });

    it("should correctly identify a Flush", async function () {
        const hand = [
            createCard(0, 0), // 2 of Hearts
            createCard(3, 0), // 5 of Hearts
            createCard(5, 0), // 7 of Hearts
            createCard(7, 0), // 9 of Hearts
            createCard(10, 0), // Queen of Hearts
            createCard(2, 1),  // 4 of Diamonds (not part of the flush)
            createCard(1, 2)   // 3 of Clubs (not part of the flush)
        ];

        const result = await cardManagement.evaluateHand(hand);
        expect(result).to.equal(5 * 1000000 + 10); // HandRanking.Flush * 1000000 + Flush Value
    });

    it("should correctly identify a Three of a Kind", async function () {
        const hand = [
            createCard(6, 0), // 8 of Hearts
            createCard(6, 1), // 8 of Diamonds
            createCard(6, 2), // 8 of Clubs
            createCard(0, 3), // 2 of Spades
            createCard(1, 0), // 3 of Hearts
            createCard(2, 1), // 4 of Diamonds
            createCard(7, 2)  // 9 of Clubs
        ];

        const result = await cardManagement.evaluateHand(hand);
        expect(result).to.equal(3 * 1000000 + 6); // HandRanking.ThreeOfAKind * 1000000 + Three of a Kind Value
    });

    it("should correctly identify Two Pairs", async function () {
        const hand = [
            createCard(8, 0), // 10 of Hearts
            createCard(8, 1), // 10 of Diamonds
            createCard(1, 2),  // 3 of Clubs
            createCard(1, 3),  // 3 of Spades
            createCard(3, 0),  // 5 of Hearts (kicker)
            createCard(4, 1),  // 6 of Diamonds
            createCard(5, 2)   // 7 of Clubs
        ];

        const result = await cardManagement.evaluateHand(hand);
        expect(result).to.equal(2 * 1000000 + 90208); // HandRanking.TwoPairs * 1000000 + Two Pairs Value
    });
});