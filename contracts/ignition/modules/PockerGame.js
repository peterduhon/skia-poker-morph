const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("Games", (m) => {
  const game = m.contract("Games", ["SkiapPoker"]);

  m.call(game, "launch", []);

  return { game };
});