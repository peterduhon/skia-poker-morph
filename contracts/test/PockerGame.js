const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Game Contract", function () {
    let Game;
    let game;
    let owner;

    beforeEach(async function () {
        Game = await ethers.getContractFactory("Game");
        game = await Game.deploy(/* constructor arguments here */);
        await game.deployed();
        [owner] = await ethers.getSigners();
    });

    it("should register a player", async function () {
        await game.registerPlayer();
        const player = await game.players(owner.address);
        expect(player.registered).to.be.true;
    });

    // Additional tests for your contract functions...
});
