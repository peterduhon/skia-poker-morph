const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BettingAndPotManagement Contract", function () {
    let BettingAndPotManagement;
    let bettingAndPotManagement;
    let CardManagement;
    let cardManagement;
    let RoomManagement;
    let roomManagement;
    let UserManagement;
    let userManagement;
    let AIPlayerManagement;
    let aiPlayerManagement;

    beforeEach(async function () {
        CardManagement = await ethers.getContractFactory("CardManagement");
        cardManagement = await CardManagement.deploy();
        await cardManagement.waitForDeployment();

        AIPlayerManagement = await ethers.getContractFactory("AIPlayerManagement");
        aiPlayerManagement = await AIPlayerManagement.deploy();
        await aiPlayerManagement.waitForDeployment();

        RoomManagement = await ethers.getContractFactory("RoomManagement");
        roomManagement = await RoomManagement.deploy();
        await roomManagement.waitForDeployment();

        UserManagement = await ethers.getContractFactory("UserManagement");
        userManagement = await UserManagement.deploy();
        await userManagement.waitForDeployment();

        BettingAndPotManagement = await ethers.getContractFactory("BettingAndPotManagement");
        bettingAndPotManagement = await BettingAndPotManagement.deploy(
            1, // roomId
            "0x3DcD01c4AeEB6a13c106989db3934132dF74Cc8c",
            cardManagement.target,
            roomManagement.target,
            userManagement.target,
            aiPlayerManagement,
            ethers.parseEther("0.005"), // minimumBet
            "0x6A2AAd07396B36Fe02a22b33cf443582f682c82f", // vrfCoordinator
            "0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06", // linkToken
            "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4", // keyHash
            ethers.parseEther("0.1") // fee
        );
        await bettingAndPotManagement.waitForDeployment();
    });

    it("Should initialize the deck and shuffle it", async function () {
        await bettingAndPotManagement.initializeDeck();

        const deck = await bettingAndPotManagement.deck();
        console.log("shuffled deck : ", deck);
        expect(deck.length).to.equal(52);
    });

    it("Should allow players to join the game", async function () {
        const [_, player1] = await ethers.getSigners();

        await bettingAndPotManagement.connect(player1).joinGame();

        const playersList = await bettingAndPotManagement.getPlayersList();
        expect(playersList).to.include(player1.address);
    });

    it("Should start the game and deal cards to players", async function () {
        const [_, player1, player2] = await ethers.getSigners();

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();

        await bettingAndPotManagement.startGame();

        const player1Hand = await bettingAndPotManagement.getPlayerHand(player1.address);
        const player2Hand = await bettingAndPotManagement.getPlayerHand(player2.address);

        expect(player1Hand.length).to.equal(2);
        expect(player2Hand.length).to.equal(2);
    });

    it("Should handle a betting round correctly", async function () {
        const [_, player1, player2] = await ethers.getSigners();

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        // Player 1 raises
        const raiseAmount = ethers.parseEther("0.2");
        await bettingAndPotManagement.connect(player1).playerAction(1, raiseAmount); // PlayerAction.Raise

        // Player 2 calls
        await bettingAndPotManagement.connect(player2).playerAction(0, raiseAmount); // PlayerAction.Call

        const potAmount = await bettingAndPotManagement.getPotAmount(0);
        expect(potAmount).to.equal(raiseAmount.mul(2));
    });

    it("Should handle the showdown and determine the winner", async function () {
        const [_, player1, player2] = await ethers.getSigners();

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        // Simulate game until showdown
        await bettingAndPotManagement.playerAction(0, 0); // PlayerAction.Call
        await bettingAndPotManagement.playerAction(0, 0); // PlayerAction.Call
        await bettingAndPotManagement.nextGameState(); // Move to Flop
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.nextGameState(); // Move to Turn
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.nextGameState(); // Move to River
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.nextGameState(); // Move to Showdown

        const winners = await bettingAndPotManagement.getWinners();
        expect(winners.length).to.be.greaterThan(0);
    });

    it("Should reset the game state correctly", async function () {
        const [_, player1, player2] = await ethers.getSigners();

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        await bettingAndPotManagement.resetGame();

        const gameState = await bettingAndPotManagement.gameState();
        expect(gameState).to.equal(0); // GameState.PreFlop
    });

    it("Should distribute pots correctly among winners", async function () {
        const [_, player1, player2] = await ethers.getSigners();

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        // Simulate game until showdown
        await bettingAndPotManagement.playerAction(0, 0); // PlayerAction.Call
        await bettingAndPotManagement.playerAction(0, 0); // PlayerAction.Call
        await bettingAndPotManagement.nextGameState(); // Move to Flop
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.nextGameState(); // Move to Turn
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.nextGameState(); // Move to River
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.playerAction(2, 0); // PlayerAction.Check
        await bettingAndPotManagement.nextGameState(); // Move to Showdown

        const potAmount = ethers.parseEther("0.4"); // Example pot amount

        // Distribute pot to player1 (winner)
        await bettingAndPotManagement.distributePots();

        const player1Balance = await userManagement.getUserBalance(player1.address);
        expect(player1Balance).to.equal(potAmount);
    });

    it("Should fail to join the game if the game has already started", async function () {
        const [_, player1] = await ethers.getSigners();

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.startGame();

        await expect(bettingAndPotManagement.connect(player1).joinGame())
            .to.be.revertedWith("Game has already started");
    });

    it("Should handle a player folding", async function () {
        const [_, player1, player2] = await ethers.getSigners();

        await bettingAndPotManagement.connect(player1).joinGame();
        await bettingAndPotManagement.connect(player2).joinGame();
        await bettingAndPotManagement.startGame();

        // Player 1 folds
        await bettingAndPotManagement.connect(player1).playerAction(3, 0); // PlayerAction.Fold

        const player1State = await bettingAndPotManagement.getPlayerState(player1.address);
        expect(player1State.isActive).to.be.false;
    });
});
