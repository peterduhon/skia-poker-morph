const { expect } = require("chai");

describe("HandEvaluator", function () {
  it("should request random numbers from Chainlink VRF", async function () {
    const HandEvaluator = await ethers.getContractFactory("HandEvaluator");
    const handEvaluator = await HandEvaluator.deploy();
    await handEvaluator.deployed();

    // Test requesting random numbers
    const tx = await handEvaluator.requestRandomNumber();
    await tx.wait();

    // Assert that the random number request was made
    expect(tx).to.emit(handEvaluator, "RandomNumberRequested");
  });
});
