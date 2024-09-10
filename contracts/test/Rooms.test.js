const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

describe("RoomManagement Contract", function () {
    let RoomManagement, roomManagement;
    let owner, player1, player2;
    const buyInAmount = ethers.parseEther("0.01");
    const roomId = 0;

    beforeEach(async function () {
        [owner, player1, player2] = await hre.ethers.getSigners();
        RoomManagement = await ethers.getContractFactory("RoomManagement");
        roomManagement = await RoomManagement.deploy();
        await roomManagement.waitForDeployment();
    });

    it("Should create a new room", async function () {
        await roomManagement.createGameRoom("Test Room", buyInAmount, 4);

        const room = await roomManagement.getGameInfo(roomId);
        expect(room.buyInAmount).to.equal(buyInAmount);
        expect(room.maxPlayers).to.equal(4);
    });

    it("Should add a player to the room", async function () {
        await roomManagement.createGameRoom("Test Room", buyInAmount, 4);
        console.log("asdfasdf", player1);
        const nickName = "Player1";
        const chips = ethers.parseEther("0.001");

        await roomManagement.addPlayer(roomId, player1.address, nickName, chips);

        const [returnedNickName, returnedChips] = await roomManagement.getPlayerInfo(roomId, player1.address);
        expect(returnedNickName).to.equal(nickName);
        expect(returnedChips).to.equal(chips);

        const players = await roomManagement.getPlayers(roomId);
        expect(players).to.include(player1.address);
    });

    it("Should update player information", async function () {
        await roomManagement.createGameRoom("Test Room", buyInAmount, 4);

        const nickName = "Player1";
        const chips = ethers.parseEther("0.001");

        await roomManagement.addPlayer(roomId, player1.address, nickName, chips);

        const newNickName = "Player1Updated";
        const newChips = ethers.parseEther("0.002");

        await roomManagement.updatePlayerInfo(roomId, player1.address, newNickName, newChips);

        const [returnedNickName, returnedChips] = await roomManagement.getPlayerInfo(roomId, player1.address);
        expect(returnedNickName).to.equal(newNickName);
        expect(returnedChips).to.equal(newChips);
    });

    it("Should remove a player from the room", async function () {
        await roomManagement.createGameRoom("Test Room", buyInAmount, 4);

        const nickName = "Player1";
        const chips = ethers.parseEther("0.001");

        await roomManagement.addPlayer(roomId, player1.address, nickName, chips);
        await roomManagement.addPlayer(roomId, player2.address, "Player2", chips);

        await roomManagement.removePlayer(roomId, player1.address);

        const players = await roomManagement.getPlayers(roomId);
        expect(players).to.not.include(player1.address);

        const [returnedNickName, returnedChips] = await roomManagement.getPlayerInfo(roomId, player1.address);
        expect(returnedNickName).to.equal(""); // Nickname should no longer exist
        expect(returnedChips).to.equal(0); // Chips should be removed
    });

    it("Should revert if non-owner tries to create a room", async function () {
        await expect(
            roomManagement.connect(player1).createGameRoom("Test Room", buyInAmount, 4)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert if non-owner tries to add a player", async function () {
        await roomManagement.createGameRoom("Test Room", buyInAmount, 4);
        await expect(
            roomManagement.connect(player1).addPlayer(roomId, player1.address, "Player1", ethers.parseEther("0.005"))
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert if non-owner tries to update player info", async function () {
        await roomManagement.createGameRoom("Test Room", buyInAmount, 4);

        const nickName = "Player1";
        const chips = ethers.parseEther("0.001");

        await roomManagement.addPlayer(roomId, player1.address, nickName, chips);
        await expect(
            roomManagement.connect(player1).updatePlayerInfo(roomId, player1.address, "UpdatedName", ethers.parseEther("0.001"))
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should update game status by creator only", async function () {
        await roomManagement.createGameRoom("Test Room", buyInAmount, 4);

        await roomManagement.updateGameStatus(roomId, 1); // 1 could represent a new status, e.g., 'Active'

        const gameRoom = await roomManagement.getGameInfo(roomId);
        expect(gameRoom.status).to.equal(1); // Ensure that status is updated as expected

        await expect(
            roomManagement.connect(player1).updateGameStatus(roomId, 2) // 2 could represent a different status
        ).to.be.revertedWith("Poker Game : Only creator can change game status.");
    });

    it("Should check if room update is available", async function () {
        await roomManagement.createGameRoom("Test Room", buyInAmount, 4);

        await roomManagement.addPlayer(roomId, player1.address, "Player1", ethers.parseEther("0.001"));

        const updateAvailable = await roomManagement.isUpdateAvailable(roomId);
        expect(updateAvailable).to.be.true;

        await roomManagement.isUpdateAvailable(roomId); // Should set the status to false
        const updateAvailableAfter = await roomManagement.isUpdateAvailable(roomId);
        expect(updateAvailableAfter).to.be.false;
    });
});
