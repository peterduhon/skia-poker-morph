const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HandEvaluate", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, addr1, addr2, addrs] = await ethers.getSigners();
    const vrfCoordinator = "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D"; // Example VRF Coordinator address
    const linkToken = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
    const HandEvaluate = await ethers.getContractFactory("HandEvaluate");
    const handEvaluate = await HandEvaluate.deploy(vrfCoordinator, linkToken);

    return { HandEvaluate, handEvaluate, owner, addr1, addr2, addrs };
  }

  beforeEach(async function () {
    // We use loadFixture to run the deployment fixture and get the necessary objects
    ({ HandEvaluate, handEvaluate, owner, addr1, addr2, addrs } =
      await deployFixture());
  });
});
