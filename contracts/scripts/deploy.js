const { ethers, upgrades } = require("hardhat");

async function main() {
    // Deploy the GameManagement contract
    const GameManagement = await ethers.getContractFactory("Games");
    const gameManagement = await GameManagement.deploy();
    await gameManagement.deployed();
    console.log("GameManagement deployed to:", gameManagement.address);

    // Deploy the RoomManagement contract
    const RoomManagement = await ethers.getContractFactory("Rooms");
    const roomManagement = await RoomManagement.deploy();
    await roomManagement.deployed();
    console.log("RoomManagement deployed to:", roomManagement.address);

    // Deploy the UserManagement contract
    const UserManagement = await ethers.getContractFactory("Users");
    const userManagement = await UserManagement.deploy();
    await userManagement.deployed();
    console.log("UserManagement deployed to:", userManagement.address);

    // Deploy the PokerGameProxy contract and link it to the Implementation contract
    // const PokerGameProxy = await ethers.getContractFactory("PokerGameProxy");
    // const proxy = await PokerGameProxy.deploy(implementation.address);
    // await proxy.deployed();
    // console.log("PokerGameProxy deployed to:", proxy.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
