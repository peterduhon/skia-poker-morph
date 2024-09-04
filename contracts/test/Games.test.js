const { expect } = require("chai");
const hre = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("GameManagement Contract", function () {
    async function deployGameManagement() {
        const [owner, admin, nonAdmin, player1] = await hre.ethers.getSigners();
        
        const common = await hre.ethers.deployContract("Common");

        const gameManagement = await hre.ethers.deployContract("GameManagement");

        await gameManagement.grantAdminRole(admin.address); // Grant ADMIN_ROLE to the admin

        return { gameManagement, owner, admin, nonAdmin, player1 };
    }

    it("Should create a game room with valid parameters", async function () {
        const { gameManagement, admin } = await loadFixture(deployGameManagement);

        const buyInAmount = hre.ethers.utils.parseEther("1");
        const maxPlayers = 5;

        const tx = await gameManagement.connect(admin).createGameRoom(buyInAmount, maxPlayers);
        const receipt = await tx.wait();

        const gameId = receipt.events[0].args.gameId.toNumber();
        const gameRoom = await gameManagement.getGameRoom(gameId);

        expect(gameRoom.id).to.equal(gameId);
        expect(gameRoom.creator).to.equal(admin.address);
        expect(gameRoom.buyInAmount).to.equal(buyInAmount);
        expect(gameRoom.maxPlayers).to.equal(maxPlayers);
        expect(gameRoom.status).to.equal(0); // GameStatus.Waiting
    });

    it("Should fail to create a game room with invalid parameters", async function () {
        const { gameManagement, admin } = await loadFixture(deployGameManagement);

        const invalidBuyInAmount = hre.ethers.utils.parseEther("0");
        const invalidMaxPlayers = 1;

        await expect(
            gameManagement.connect(admin).createGameRoom(invalidBuyInAmount, 5)
        ).to.be.revertedWith("Buy-in amount must be greater than 0");

        await expect(
            gameManagement.connect(admin).createGameRoom(hre.ethers.utils.parseEther("1"), invalidMaxPlayers)
        ).to.be.revertedWith("Number of players must be greater than 1");
    });

    it("Should update the game status", async function () {
        const { gameManagement, admin } = await loadFixture(deployGameManagement);

        const buyInAmount = hre.ethers.utils.parseEther("1");
        const maxPlayers = 5;

        const tx = await gameManagement.connect(admin).createGameRoom(buyInAmount, maxPlayers);
        const receipt = await tx.wait();
        const gameId = receipt.events[0].args.gameId.toNumber();

        await gameManagement.connect(admin).updateGameStatus(gameId, 1); // 1 represents GameStatus.Started

        const gameRoom = await gameManagement.getGameRoom(gameId);
        expect(gameRoom.status).to.equal(1); // GameStatus.Started
    });

    it("Should fail to update the game status if not admin", async function () {
        const { gameManagement, nonAdmin } = await loadFixture(deployGameManagement);

        await expect(gameManagement.connect(nonAdmin).updateGameStatus(1, 1))
            .to.be.revertedWith(/AccessControl: account .* is missing role/);
    });

    it("Should retrieve game room details", async function () {
        const { gameManagement, admin } = await loadFixture(deployGameManagement);

        const buyInAmount = hre.ethers.utils.parseEther("1");
        const maxPlayers = 5;

        const tx = await gameManagement.connect(admin).createGameRoom(buyInAmount, maxPlayers);
        const receipt = await tx.wait();
        const gameId = receipt.events[0].args.gameId.toNumber();

        const gameRoom = await gameManagement.getGameRoom(gameId);

        expect(gameRoom.buyInAmount).to.equal(buyInAmount);
        expect(gameRoom.maxPlayers).to.equal(maxPlayers);
    });

    it("Should retrieve user games", async function () {
        const { gameManagement, admin, player1 } = await loadFixture(deployGameManagement);

        const buyInAmount = hre.ethers.utils.parseEther("1");
        const maxPlayers = 5;

        const tx1 = await gameManagement.connect(admin).createGameRoom(buyInAmount, maxPlayers);
        const receipt1 = await tx1.wait();
        const gameId1 = receipt1.events[0].args.gameId.toNumber();

        const tx2 = await gameManagement.connect(admin).createGameRoom(buyInAmount, maxPlayers);
        const receipt2 = await tx2.wait();
        const gameId2 = receipt2.events[0].args.gameId.toNumber();

        const userGames = await gameManagement.getUserGames(admin.address);
        expect(userGames).to.deep.equal([gameId1, gameId2]);
    });

    it("Should grant and revoke admin role", async function () {
        const { gameManagement, owner, nonAdmin } = await loadFixture(deployGameManagement);

        await gameManagement.grantAdminRole(nonAdmin.address);

        expect(await gameManagement.hasRole(gameManagement.ADMIN_ROLE(), nonAdmin.address)).to.be.true;

        await gameManagement.connect(owner).revokeRole(gameManagement.ADMIN_ROLE(), nonAdmin.address);

        expect(await gameManagement.hasRole(gameManagement.ADMIN_ROLE(), nonAdmin.address)).to.be.false;
    });

    it("Should fail to create a game room if not admin", async function () {
        const { gameManagement, nonAdmin } = await loadFixture(deployGameManagement);

        const buyInAmount = hre.ethers.utils.parseEther("1");
        const maxPlayers = 5;

        await expect(
            gameManagement.connect(nonAdmin).createGameRoom(buyInAmount, maxPlayers)
        ).to.be.revertedWith(/AccessControl: account .* is missing role/);
    });

    it("Should return correct buy-in amount and max players for a game", async function () {
        const { gameManagement, admin } = await loadFixture(deployGameManagement);

        const buyInAmount = hre.ethers.utils.parseEther("1");
        const maxPlayers = 5;

        const tx = await gameManagement.connect(admin).createGameRoom(buyInAmount, maxPlayers);
        const receipt = await tx.wait();
        const gameId = receipt.events[0].args.gameId.toNumber();

        const storedBuyInAmount = await gameManagement.getBuyInAmount(gameId);
        const storedMaxPlayers = await gameManagement.maxPlayers(gameId);

        expect(storedBuyInAmount).to.equal(buyInAmount);
        expect(storedMaxPlayers).to.equal(maxPlayers);
    });

    it("Should fail to get details of non-existing game room", async function () {
        const { gameManagement } = await loadFixture(deployGameManagement);

        await expect(gameManagement.getGameRoom(999)).to.be.revertedWith("Game room does not exist");
    });
});
