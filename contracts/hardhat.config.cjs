require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    holesky: {
      url: "https://rpc-quicknode-holesky.morphl2.io/", // Replace with the actual Morph RPC URL for Holesky
      accounts: [process.env.PRIVATE_KEY], // Replace with your account's private key
    },
  },
};
