const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RoomManagement Contract", function () {
    let RoomManagement, roomManagement;
    const roomId = 1;
    const buyInAmount = ethers.parseEther("0.01");

    beforeEach(async function () {
        RoomManagement = await ethers.getContractFactory("RoomManagement");
        roomManagement = await RoomManagement.deploy();
        await roomManagement.waitForDeployment();
    });

    it("Should create a new room", async function () {
        await roomManagement.createRoom(roomId, buyInAmount);

        const roomBuyIn = await roomManagement.getBuyInAmount(roomId);
        expect(roomBuyIn).to.equal(buyInAmount);
    });

    it("Should add a player to the room", async function () {
        await roomManagement.createRoom(roomId, buyInAmount);
        const [ player1 ] = await ethers.getSigners();
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
        await roomManagement.createRoom(roomId, buyInAmount);
        const nickName = "Player1";
        const [ player1 ] = await ethers.getSigners();
        const chips = ethers.parseEther("0.001");

        await roomManagement.addPlayer(roomId, player1.address, nickName, chips);

        const newNickName = "Player1Updated";
        const newChips = ethers.parseEther("0.001");

        await roomManagement.updatePlayerInfo(roomId, player1.address, newNickName, newChips);

        const [returnedNickName, returnedChips] = await roomManagement.getPlayerInfo(roomId, player1.address);
        expect(returnedNickName).to.equal(newNickName);
        expect(returnedChips).to.equal(newChips);
    });

    it("Should remove a player from the room", async function () {
        await roomManagement.createRoom(roomId, buyInAmount);
        const nickName = "Player1";
        const [ player1, player2 ] = await ethers.getSigners();
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
      const [ player1 ] = await ethers.getSigners();
      await expect(
            roomManagement.connect(player1).createRoom(roomId, buyInAmount)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert if non-owner tries to add a player", async function () {
      const [ player1 ] = await ethers.getSigners();
      await roomManagement.createRoom(roomId, buyInAmount);
        await expect(
            roomManagement.connect(player1).addPlayer(roomId, player1.address, "Player1", ethers.parseEther("0.005"))
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert if non-owner tries to update player info", async function () {
        await roomManagement.createRoom(roomId, buyInAmount);
        const nickName = "Player1";
        const [ player1 ] = await ethers.getSigners();
        const chips = ethers.parseEther("0.001");

        await roomManagement.addPlayer(roomId, player1.address, nickName, chips);
        await expect(
            roomManagement.connect(player1).updatePlayerInfo(roomId, player1.address, "UpdatedName", ethers.parseEther("0.001"))
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });
});