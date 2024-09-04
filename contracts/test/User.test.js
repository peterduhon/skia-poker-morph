const { expect } = require("chai");
const hre = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("UserManagement Contract", function () {
    async function deployUserManagement() {
        const userManagement = await hre.ethers.deployContract("UserManagement");
        return { userManagement };
    }

    it("Should register a new user", async function () {
        const username = "Alice";
        const [user1] = await hre.ethers.getSigners();
        const initialBalance = ethers.parseEther("1");
        const { userManagement } = await loadFixture(deployUserManagement);

        await userManagement.connect(user1).registerUser(username, { value: initialBalance });

        const nickname = await userManagement.getUserNickName(user1);
        const balance = await userManagement.getUserBalance(user1);
        expect(nickname).to.equal(username);
        expect(balance).to.equal(initialBalance);
    });

    it("Should fail to register a user with no balance", async function () {
        const username = "Bob";
        const [user2] = await hre.ethers.getSigners();
        const { userManagement } = await loadFixture(deployUserManagement);
        await expect(
            userManagement.connect(user2).registerUser(username, { value: 0 })
        ).to.be.revertedWith("Initial balance must be greater than 0");
    });

    it("Should update the user's balance", async function () {
        const username = "Charlie";
        const [admin, user3] = await hre.ethers.getSigners();
        const initialBalance = ethers.parseEther("1");
        const additionalBalance = ethers.parseEther("0.5");
        const { userManagement } = await loadFixture(deployUserManagement);

        await userManagement.connect(user3).registerUser(username, { value: initialBalance });

        console.log("1");

        await userManagement.connect(admin).updateBalance(user3, additionalBalance);

        console.log("2");

        const balance = await userManagement.getUserBalance(user3);
        console.log("result : ", balance);
        console.log("expected : ", initialBalance.add(additionalBalance));
        expect(balance).to.equal(initialBalance.add(additionalBalance));
    });

    it("Should withdraw funds for the user", async function () {
        const username = "Dave";
        const [user4] = await hre.ethers.getSigners();
        const initialBalance = ethers.parseEther("2");
        const withdrawAmount = ethers.parseEther("1");
        const { userManagement } = await loadFixture(deployUserManagement);

        await userManagement.connect(user4).registerUser(username, { value: initialBalance });

        await userManagement.connect(user4).withdraw(withdrawAmount);

        const balance = await userManagement.getUserBalance(user4);
        expect(balance).to.equal(initialBalance.sub(withdrawAmount));
    });

    it("Should not allow non-admin to update the balance", async function () {
        const username = "Eve";
        const [user5, nonAdmin] = await hre.ethers.getSigners();
        const initialBalance = ethers.parseEther("1");
        const additionalBalance = ethers.parseEther("0.5");
        const { userManagement } = await loadFixture(deployUserManagement);

        await userManagement.connect(user5).registerUser(username, { value: initialBalance });

        await expect(
            userManagement.connect(nonAdmin).updateBalance(user5, additionalBalance)
        ).to.be.revertedWith("AccessControl: account " + nonAdmin.address.toLowerCase() + " is missing role");
    });

    it("Should return the correct nickname", async function () {
        const username = "Frank";
        const [user6] = await hre.ethers.getSigners();
        const initialBalance = ethers.parseEther("1");
        const { userManagement } = await loadFixture(deployUserManagement);

        await userManagement.connect(user6).registerUser(username, { value: initialBalance });

        const nickname = await userManagement.getUserNickName(user6);
        expect(nickname).to.equal(username);
    });

    it("Should return the correct balance", async function () {
        const username = "Grace";
        const [user7] = await hre.ethers.getSigners();
        const initialBalance = ethers.parseEther("1");
        const { userManagement } = await loadFixture(deployUserManagement);

        await userManagement.connect(user7).registerUser(username, { value: initialBalance });

        const balance = await userManagement.getUserBalance(user7);
        expect(balance).to.equal(initialBalance);
    });
});
