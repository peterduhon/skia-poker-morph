const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HandEvaluator", function () {
  let HandEvaluator;
  let handEvaluator;

  beforeEach(async function () {
    HandEvaluator = await ethers.getContractFactory("HandEvaluator");
    handEvaluator = await HandEvaluator.deploy(/* constructor arguments */);
    await handEvaluator.deployed();
  });

  describe("Hand Evaluation", function () {
    it("Should correctly identify a Royal Flush", async function () {
      const hand = [
        { suit: 0, value: 9 },  // 10 of Spades
        { suit: 0, value: 10 }, // Jack of Spades
        { suit: 0, value: 11 }, // Queen of Spades
        { suit: 0, value: 12 }, // King of Spades
        { suit: 0, value: 13 }, // Ace of Spades
        { suit: 1, value: 0 },  // Two of Hearts (irrelevant)
        { suit: 2, value: 1 }   // Three of Diamonds (irrelevant)
      ];
      expect(await handEvaluator.evaluateHand(hand)).to.equal(ethers.BigNumber.from(10 ** 24 + 13)); // Royal Flush with Ace high
    });

    it("Should correctly identify a Straight Flush", async function () {
      const hand = [
        { suit: 0, value: 5 },  // 6 of Spades
        { suit: 0, value: 6 }, // 7 of Spades
        { suit: 0, value: 7 }, // 8 of Spades
        { suit: 0, value: 8 }, // 9 of Spades
        { suit: 0, value: 9 }, // 10 of Spades
        { suit: 1, value: 0 },  // Two of Hearts (irrelevant)
        { suit: 2, value: 1 }   // Three of Diamonds (irrelevant)
      ];
      expect(await handEvaluator.evaluateHand(hand)).to.equal(ethers.BigNumber.from(9 * 10 ** 24 + 10)); // Straight Flush with 10 high
    });

    it("Should correctly identify Four of a Kind", async function () {
      const hand = [
        { suit: 0, value: 5 },  // 6 of Spades
        { suit: 1, value: 5 }, // 6 of Hearts
        { suit: 2, value: 5 }, // 6 of Diamonds
        { suit: 3, value: 5 }, // 6 of Clubs
        { suit: 0, value: 9 }, // 10 of Spades
        { suit: 1, value: 0 },  // Two of Hearts (irrelevant)
        { suit: 2, value: 1 }   // Three of Diamonds (irrelevant)
      ];
      expect(await handEvaluator.evaluateHand(hand)).to.equal(ethers.BigNumber.from(8 * 10 ** 24 + 6 * 10 ** 20 + 10 * 10 ** 16)); // Four of a Kind with 6s and 10 kicker
    });

    it("Should correctly identify a Full House", async function () {
      const hand = [
        { suit: 0, value: 5 },  // 6 of Spades
        { suit: 1, value: 5 }, // 6 of Hearts
        { suit: 2, value: 5 }, // 6 of Diamonds
        { suit: 0, value: 9 }, // 10 of Spades
        { suit: 0, value: 9 }, // 10 of Spades
        { suit: 1, value: 0 },  // Two of Hearts (irrelevant)
        { suit: 2, value: 1 }   // Three of Diamonds (irrelevant)
      ];
      expect(await handEvaluator.evaluateHand(hand)).to.equal(ethers.BigNumber.from(7 * 10const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HandEvaluator", function () {
  let HandEvaluator;
  let handEvaluator;

  beforeEach(async function () {
    HandEvaluator = await ethers.getContractFactory("HandEvaluator");
    handEvaluator = await HandEvaluator.deploy(/* constructor arguments */);
    await handEvaluator.deployed();
  });

  describe("Hand Evaluation", function () {
    it("Should correctly identify a Royal Flush", async function () {
      const hand = [
        { suit: 0, value: 9 },  // 10 of Spades
        { suit: 0, value: 10 }, // Jack of Spades
        { suit: 0, value: 11 }, // Queen of Spades
        { suit: 0, value: 12 }, // King of Spades
        { suit: 0, value: 13 }, // Ace of Spades
        { suit: 1, value: 0 },  // Two of Hearts (irrelevant)
        { suit: 2, value: 1 }   // Three of Diamonds (irrelevant)
      ];
      expect(await handEvaluator.evaluateHand(hand)).to.equal(ethers.BigNumber.from(10 ** 24 + 13)); // Royal Flush with Ace high
    });

    it("Should correctly identify a Straight Flush", async function () {
      const hand = [
        { suit: 0, value: 5 },  // 6 of Spades
        { suit: 0, value: 6 }, // 7 of Spades
        { suit: 0, value: 7 }, // 8 of Spades
        { suit: 0, value: 8 }, // 9 of Spades
        { suit: 0, value: 9 }, // 10 of Spades
        { suit: 1, value: 0 },  // Two of Hearts (irrelevant)
        { suit: 2, value: 1 }   // Three of Diamonds (irrelevant)
      ];
      expect(await handEvaluator.evaluateHand(hand)).to.equal(ethers.BigNumber.from(9 * 10 ** 24 + 10)); // Straight Flush with 10 high
    });

    it("Should correctly identify Four of a Kind", async function () {
      const hand = [
        { suit: 0, value: 5 },  // 6 of Spades
        { suit: 1, value: 5 }, // 6 of Hearts
        { suit: 2, value: 5 }, // 6 of Diamonds
        { suit: 3, value: 5 }, // 6 of Clubs
        { suit: 0, value: 9 }, // 10 of Spades
        { suit: 1, value: 0 },  // Two of Hearts (irrelevant)
        { suit: 2, value: 1 }   // Three of Diamonds (irrelevant)
      ];
      expect(await handEvaluator.evaluateHand(hand)).to.equal(ethers.BigNumber.from(8 * 10 ** 24 + 6 * 10 ** 20 + 10 * 10 ** 16)); // Four of a Kind with 6s and 10 kicker
    });

    it("Should correctly identify a Full House", async function () {
      const hand = [
        { suit: 0, value: 5 },  // 6 of Spades
        { suit: 1, value: 5 }, // 6 of Hearts
        { suit: 2, value: 5 }, // 6 of Diamonds
        { suit: 0, value: 9 }, // 10 of Spades
        { suit: 0, value: 9 }, // 10 of Spades
        { suit: 1, value: 0 },  // Two of Hearts (irrelevant)
        { suit: 2, value: 1 }   // Three of Diamonds (irrelevant)
      ];
      expect(await handEvaluator.evaluateHand(hand)).to.equal(ethers.BigNumber.from(7 * 10** 24 + 6 * 10 ** 20 + 10 * 10 ** 16));
    
      describe("All-in handling", function () {
        it("Should handle three players going all-in with different amounts", async function () {
          // Set up a game state with three players, Player A, Player B, and Player C
          // Player A goes all-in with 30% of the current pot
          // Player B goes all-in with 60% of the current pot
          // Player C goes all-in with 100% of the current pot
    
          // Call the handleAllIn function with Player A as the input
          await handEvaluator.handleAllIn(PlayerA, 300);
    
          // Call the handleAllIn function with Player B as the input
          await handEvaluator.handleAllIn(PlayerB, 600);
    
          // Call the handleAllIn function with Player C as the input
          await handEvaluator.handleAllIn(PlayerC, 1000);
    
          // Assert that the remaining pot is split into three side pots
          expect(handEvaluator.pot.amount).to.equal(0);
          expect(handEvaluator.sidePots[0].amount).to.equal(150);
          expect(handEvaluator.sidePots[1].amount).to.equal(300);
          expect(handEvaluator.sidePots[2].amount).to.equal(550);});})
    });

      