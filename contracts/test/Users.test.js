const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UserManagement Contract", function () {
    let UserManagement, userManagement;
    
    beforeEach(async function () {
        UserManagement = await ethers.getContractFactory("UserManagement");
        userManagement = await UserManagement.deploy();
        await userManagement.waitForDeployment();
    });

    it("Should withdraw funds for the user", async function () {
        const username = "Dave";
        const [user4] = await ethers.getSigners();
        const initialBalance = ethers.parseEther("0.1");
        const withdrawAmount = ethers.parseEther("0.05");

        await userManagement.connect(user4).registerUser(username, { value: initialBalance });
        await userManagement.connect(user4).withdraw(withdrawAmount);

        const balance = await userManagement.getUserBalance(user4.address);
        expect(balance).to.equal(1);
    });

    it("Should not allow non-admin to update the balance", async function () {
        const username = "Eve";
        const [user5, nonAdmin] = await ethers.getSigners();
        const initialBalance = ethers.parseEther("0.1");
        const additionalBalance = ethers.parseEther("0.05");

        await userManagement.connect(user5).registerUser(username, { value: initialBalance });

        await expect(
            userManagement.connect(nonAdmin).updateBalance(user5.address, additionalBalance)
        ).to.be.revertedWith("AccessControl: account " + nonAdmin.address.toLowerCase() + " is missing role");
    });

    it("Should return the correct nickname", async function () {
        const username = "Frank";
        const [user6] = await ethers.getSigners();
        const initialBalance = ethers.parseEther("0.05");

        await userManagement.connect(user6).registerUser(username, { value: initialBalance });

        const nickname = await userManagement.getUserNickName(user6.address);
        expect(nickname).to.equal(username);
    });

    it("Should return the correct balance", async function () {
        const username = "Grace";
        const [user7] = await ethers.getSigners();
        const initialBalance = ethers.parseEther("0.05");

        await userManagement.connect(user7).registerUser(username, { value: initialBalance });

        const balance = await userManagement.getUserBalance(user7.address);
        expect(balance).to.equal(1);
    });
});