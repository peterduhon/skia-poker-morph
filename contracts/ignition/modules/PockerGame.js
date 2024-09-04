const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("PokerGame", (m) => {
  const game = m.contract("Game", ["GameManagement"]);

  m.call(game, "launch", []);

  return { game };
});