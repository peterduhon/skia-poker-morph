const { ethers } = require("hardhat");
// scripts/deploy.js

async function main() {
    // Get the contract factories
    const GameManagement = await ethers.getContractFactory("GameManagement");
    const RoomManagement = await ethers.getContractFactory("RoomManagement");
    const UserManagement = await ethers.getContractFactory("UserManagement");
    const BettingAndPotManagement = await ethers.getContractFactory("BettingAndPotManagement");
    const CardManagement = await ethers.getContractFactory("CardManagement");
    const PokerGameProxy = await ethers.getContractFactory("SkiaPokerProxy");
  
    // Deploy the contracts
    const gameManagement = await GameManagement.deploy();
    await gameManagement.waitForDeployment();
    console.log("GameManagement deployed to:", gameManagement.target);
  
    const roomManagement = await RoomManagement.deploy();
    await roomManagement.waitForDeployment();
    console.log("RoomManagement deployed to:", roomManagement.target);
  
    const userManagement = await UserManagement.deploy();
    await userManagement.waitForDeployment();
    console.log("UserManagement deployed to:", userManagement.target);
    
    const cardManagement = await CardManagement.deploy();
    await cardManagement.waitForDeployment();
    console.log("CardManagement deployed to:", cardManagement.target);

    const bettingAndPotManagement = await BettingAndPotManagement.deploy(
      0,
      cardManagement.target,
      roomManagement.target,
      userManagement.target,
      ethers.parseEther("0.1"),
      "0x6A2AAd07396B36Fe02a22b33cf443582f682c82f",
      "0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06",
      "0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314",
      ethers.parseEther("0.005")
    );
    await bettingAndPotManagement.waitForDeployment();
    console.log("BettingAndPotManagement deployed to:", bettingAndPotManagement.target);
    
    // Deploy the proxy contract, pointing it to the implementation contract
    const proxy = await PokerGameProxy.deploy(gameManagement.target);
    await proxy.waitForDeployment();
    console.log("PokerGameProxy deployed to:", proxy.target);
  
    // Further steps, if needed (e.g., initializing proxy, setting roles, etc.)
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  