const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Skia Poker", function () {
  let GameManagement, RoomManagement, UserManagement, CardManagement, BettingAndPotManagement;
  let gameManagement, roomManagement, userManagement, cardManagement, bettingAndPotManagement;
  let owner, addr1, addr2;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    GameManagement = await ethers.getContractFactory("Games");
    RoomManagement = await ethers.getContractFactory("Rooms");
    UserManagement = await ethers.getContractFactory("Users");
    CardManagement = await ethers.getContractFactory("Cards");
    BettingAndPotManagement = await ethers.getContractFactory("Actions");
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the contracts
    gameManagement = await GameManagement.deploy();
    roomManagement = await RoomManagement.deploy();
    userManagement = await UserManagement.deploy();
    cardManagement = await UserManagement.deploy();
    bettingAndPotManagement = await BettingAndPotManagement.deploy(
      1, // roomId
      ethers.constants.AddressZero, // cardManagementAddress (replace with actual address)
      roomManagement.address,
      userManagement.address,
      ethers.utils.parseEther("0.1"), // minimumBet
      ethers.constants.AddressZero, // vrfCoordinator (replace with actual address)
      ethers.constants.AddressZero, // linkToken (replace with actual address)
      ethers.utils.formatBytes32String("keyhash"), // keyHash
      ethers.utils.parseEther("0.1") // fee
    );

    // Grant necessary roles
    await gameManagement.grantAdminRole(owner.address);
    await userManagement.grantGameContractRole(bettingAndPotManagement.address);
  });

  describe("GameManagement", function () {
    it("Should create a game room", async function () {
      await gameManagement.createGameRoom(ethers.utils.parseEther("1"), 6);
      const gameRoom = await gameManagement.getGameRoom(0);
      expect(gameRoom.buyInAmount).to.equal(ethers.utils.parseEther("1"));
      expect(gameRoom.maxPlayers).to.equal(6);
    });
  });

  describe("RoomManagement", function () {
    it("Should create a room", async function () {
      await roomManagement.createRoom(1, ethers.utils.parseEther("1"));
      const buyInAmount = await roomManagement.getBuyInAmount(1);
      expect(buyInAmount).to.equal(ethers.utils.parseEther("1"));
    });
  });

  describe("UserManagement", function () {
    it("Should register a user", async function () {
      await userManagement.connect(addr1).registerUser("Player1", { value: ethers.utils.parseEther("1") });
      const balance = await userManagement.getUserBalance(addr1.address);
      expect(balance).to.equal(ethers.utils.parseEther("1"));
    });
  });

  describe("BettingAndPotManagement", function () {
    it("Should allow a player to join the game", async function () {
      await userManagement.connect(addr1).registerUser("Player1", { value: ethers.utils.parseEther("1") });
      await bettingAndPotManagement.connect(addr1).joinGame({ value: ethers.utils.parseEther("1") });
      const players = await bettingAndPotManagement.getPlayers();
      expect(players).to.include(addr1.address);
    });
  });
});