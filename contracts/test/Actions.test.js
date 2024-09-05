const { expect } = require("chai");
const hre = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("BettingAndPotManagement Contract", function () {
    async function deployBettingAndPotManagement() {
        const [owner, player1, player2, player3] = await hre.ethers.getSigners();
        const cardManagement = await hre.ethers.deployContract("CardManagement");
        const roomManagement = await hre.ethers.deployContract("RoomManagement");
        const userManagement = await hre.ethers.deployContract("UserManagement");
        
        const vrfCoordinator = "0x6A2AAd07396B36Fe02a22b33cf443582f682c82f";
        const linkToken = "0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06";
        const keyHash = "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4";
        const fee = ethers.parseEther("0.1");

        const minimumBet = ethers.parseEther("0.005");
        const roomId = 1;

        const bettingAndPotManagement = await hre.ethers.deployContract(
            "BettingAndPotManagement",
            [
                roomId,
                cardManagement.target,
                roomManagement.target,
                userManagement.target,
                minimumBet,
                vrfCoordinator,
                linkToken,
                keyHash,
                fee,
            ]
        );

        return { bettingAndPotManagement, owner, player1, player2, player3, cardManagement, roomManagement, userManagement };
    }

    it("Should initialize the deck and shuffle it", async function () {
        const { bettingAndPotManagement } = await loadFixture(deployBettingAndPotManagement);
        
        await bettingAndPotManagement.initializeDeck();

        const deck = await bettingAndPotManagement.deck;
        console.log("suffled deck : ", deck);
        expect(deck.length).to.equal(52);
    });

    it("Should allow players to join the game", async function () {     //need to cooperate with RoomManagement registerPlayer
        const { bettingAndPotManagement, player1 } = await loadFixture(deployBettingAndPotManagement);

        await bettingAndPotManagement.connect(player1).joinGame();

        const playersList = await bettingAndPotManagement.getPlayersList();
        expect(playersList).to.include(player1.address);
    });

    it("Should start the game and deal cards to players", async function () {
        const { bettingAndPotManagement, owner, player1, player2 } = await loadFixture(deployBettingAndPotManagement);

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();

        await bettingAndPotManagement.startGame();

        const player1Hand = await bettingAndPotManagement.getPlayerHand(player1.address);
        const player2Hand = await bettingAndPotManagement.getPlayerHand(player2.address);

        expect(player1Hand.length).to.equal(2);
        expect(player2Hand.length).to.equal(2);
    });

    it("Should handle a betting round correctly", async function () {
        const { bettingAndPotManagement, player1, player2 } = await loadFixture(deployBettingAndPotManagement);

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        // Player 1 raises
        const raiseAmount = ethers.parseEther("0.2");
        await bettingAndPotManagement.connect(player1).playerAction(PlayerAction.Raise, raiseAmount);

        // Player 2 calls
        await bettingAndPotManagement.connect(player2).playerAction(PlayerAction.Call, raiseAmount);

        const potAmount = await bettingAndPotManagement.getPotAmount(0);
        expect(potAmount).to.equal(raiseAmount.mul(2));
    });

    it("Should handle the showdown and determine the winner", async function () {
        const { bettingAndPotManagement, player1, player2, cardManagement } = await loadFixture(deployBettingAndPotManagement);

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        // Simulate game until showdown
        await bettingAndPotManagement.playerAction(PlayerAction.Call, 0);
        await bettingAndPotManagement.playerAction(PlayerAction.Call, 0);
        await bettingAndPotManagement.nextGameState(); // Move to Flop
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.nextGameState(); // Move to Turn
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.nextGameState(); // Move to River
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.nextGameState(); // Move to Showdown

        const winners = await bettingAndPotManagement.getWinners();
        expect(winners.length).to.be.greaterThan(0);
    });

    it("Should reset the game state correctly", async function () {
        const { bettingAndPotManagement, player1, player2 } = await loadFixture(deployBettingAndPotManagement);

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        await bettingAndPotManagement.resetGame();

        const gameState = await bettingAndPotManagement.gameState();
        expect(gameState).to.equal(GameState.PreFlop);
    });

    it("Should distribute pots correctly among winners", async function () {
        const { bettingAndPotManagement, player1, player2, userManagement } = await loadFixture(deployBettingAndPotManagement);

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        // Simulate game until showdown
        await bettingAndPotManagement.playerAction(PlayerAction.Call, 0);
        await bettingAndPotManagement.playerAction(PlayerAction.Call, 0);
        await bettingAndPotManagement.nextGameState(); // Move to Flop
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.nextGameState(); // Move to Turn
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.nextGameState(); // Move to River
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.playerAction(PlayerAction.Check, 0);
        await bettingAndPotManagement.nextGameState(); // Move to Showdown

        const potAmount = ethers.parseEther("0.4"); // Example pot amount

        // Distribute pot to player1 (winner)
        await bettingAndPotManagement.distributePots();

        const player1Balance = await userManagement.getUserBalance(player1.address);
        expect(player1Balance).to.equal(potAmount);
    });

    it("Should fail to join the game if the game has already started", async function () {
        const { bettingAndPotManagement, player1 } = await loadFixture(deployBettingAndPotManagement);

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.startGame();

        await expect(bettingAndPotManagement.connect(player1).joinGame())
            .to.be.revertedWith("Game has already started");
    });

    it("Should handle a player folding", async function () {
        const { bettingAndPotManagement, player1, player2 } = await loadFixture(deployBettingAndPotManagement);

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        // Player 1 folds
        await bettingAndPotManagement.connect(player1).playerAction(PlayerAction.Fold, 0);

        const player1State = await bettingAndPotManagement.getPlayerState(player1.address);
        expect(player1State.isActive).to.be.false;
    });
});