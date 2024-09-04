const { ethers } = require("hardhat");
// scripts/deploy.js

async function main() {
    // Get the contract factories
    // const GameManagement = await ethers.getContractFactory("GameManagement");
    // const RoomManagement = await ethers.getContractFactory("RoomManagement");
    // const UserManagement = await ethers.getContractFactory("UserManagement");
    const BettingAndPotManagement = await ethers.getContractFactory("BettingAndPotManagement");
    // const CardManagement = await ethers.getContractFactory("CardManagement");
    // const PokerGameProxy = await ethers.getContractFactory("SkiaPokerProxy");
  
    // Deploy the contracts
    // const gameManagement = await GameManagement.deploy();
    // await gameManagement.waitForDeployment();
    // console.log("GameManagement deployed to:", gameManagement.target);
  
    // const roomManagement = await RoomManagement.deploy();
    // await roomManagement.waitForDeployment();
    // console.log("RoomManagement deployed to:", roomManagement.target);
  
    // const userManagement = await UserManagement.deploy();
    // await userManagement.waitForDeployment();
    // console.log("UserManagement deployed to:", userManagement.target);
  
    const bettingAndPotManagement = await BettingAndPotManagement.deploy();
    await bettingAndPotManagement.waitForDeployment();
    console.log("BettingAndPotManagement deployed to:", bettingAndPotManagement.target);
  
    // const cardManagement = await CardManagement.deploy();
    // await cardManagement.waitForDeployment();
    // console.log("CardManagement deployed to:", cardManagement.target);
  
    // // Deploy the proxy contract, pointing it to the implementation contract
    // const proxy = await PokerGameProxy.deploy("0xC7900FAB8D7Ee687D8a6b5ef5c7eB9eE2332Dc4b");
    // await proxy.waitForDeployment();
    // console.log("PokerGameProxy deployed to:", proxy.target);
  
    // Further steps, if needed (e.g., initializing proxy, setting roles, etc.)
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  