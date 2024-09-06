const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

describe("UserManagement Contract", function () {
    let UserManagement, userManagement;
    let owner, user1, user2, gameContract;

    beforeEach(async function () {
        [owner, user1, user2, gameContract] = await hre.ethers.getSigners();;
        UserManagement = await ethers.getContractFactory("UserManagement");
        userManagement = await UserManagement.deploy();
        await userManagement.waitForDeployment();
        await userManagement.grantGameContractRole(gameContract.address);
    });

    it("Should register a user and set balance correctly", async function () {
        const username = "Dave";
        const initialBalance = ethers.parseEther("0.01");
        console.log("---------", user1);

        await userManagement.connect(user1).registerUser(username, { value: initialBalance });

        const balance = await userManagement.getUserBalance(user1.address);
        const nickname = await userManagement.getUserNickName(user1.address);
        const isRegistered = await userManagement.isUserRegistered(user1.address);

        expect(balance).to.equal(initialBalance);
        expect(nickname).to.equal(username);
        expect(isRegistered).to.be.true;
    });

    it("Should withdraw funds for the user", async function () {
        const username = "Dave";
        const initialBalance = ethers.parseEther("0.01");
        const withdrawAmount = ethers.parseEther("0.005");

        await userManagement.connect(user1).registerUser(username, { value: initialBalance });
        await userManagement.connect(user1).withdraw(withdrawAmount);

        const balance = await userManagement.getUserBalance(user1.address);
        const userBalanceAfterWithdraw = await ethers.provider.getBalance(user1.address);

        expect(balance).to.equal(initialBalance.sub(withdrawAmount));
        expect(userBalanceAfterWithdraw).to.be.closeTo(
            initialBalance.sub(withdrawAmount).add(await ethers.provider.getBalance(user1.address)),
            ethers.parseEther("0.01") // Account for gas fees
        );
    });

    it("Should not allow non-admin to update the balance", async function () {
        const username = "Eve";
        const initialBalance = ethers.parseEther("0.01");
        const additionalBalance = ethers.parseEther("0.005");

        await userManagement.connect(user1).registerUser(username, { value: initialBalance });

        await expect(
            userManagement.connect(user2).updateBalance(user1.address, additionalBalance)
        ).to.be.revertedWith("AccessControl: account " + user2.address.toLowerCase() + " is missing role");
    });

    it("Should allow game contract to update balance", async function () {
        const username = "Eve";
        const initialBalance = ethers.parseEther("0.01");
        const additionalBalance = ethers.parseEther("0.005");

        await userManagement.connect(user1).registerUser(username, { value: initialBalance });
        await userManagement.connect(gameContract).updateBalance(user1.address, additionalBalance);

        const balance = await userManagement.getUserBalance(user1.address);
        expect(balance).to.equal(initialBalance.add(additionalBalance));
    });

    it("Should return the correct nickname", async function () {
        const username = "Frank";
        const initialBalance = ethers.parseEther("0.05");

        await userManagement.connect(user1).registerUser(username, { value: initialBalance });

        const nickname = await userManagement.getUserNickName(user1.address);
        expect(nickname).to.equal(username);
    });

    it("Should return the correct balance", async function () {
        const username = "Grace";
        const initialBalance = ethers.parseEther("0.005");

        await userManagement.connect(user1).registerUser(username, { value: initialBalance });

        const balance = await userManagement.getUserBalance(user1.address);
        expect(balance).to.equal(initialBalance);
    });

    it("Should revert on withdraw if insufficient balance", async function () {
        const username = "InsufficientFunds";
        const initialBalance = ethers.parseEther("0.01");
        const withdrawAmount = ethers.parseEther("0.001");

        await userManagement.connect(user1).registerUser(username, { value: initialBalance });

        await expect(
            userManagement.connect(user1).withdraw(withdrawAmount)
        ).to.be.revertedWith("Insufficient balance");
    });

    it("Should revert on register if username is empty", async function () {
        await expect(
            userManagement.connect(user1).registerUser("", { value: ethers.parseEther("0.001") })
        ).to.be.revertedWith("Username cannot be empty");
    });
});