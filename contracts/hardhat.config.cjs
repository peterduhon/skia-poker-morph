require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

const {API_URL, PRIVATE_KEY, PRIVATE_KEY_LOCAL} = process.env;

module.exports = {
  solidity: {
    compilers: [{
      version: '0.8.19',
      settings: {
        optimizer: {
          enabled: true,
          runs: 500
        }
      }
    }]
  },

  defaultNetwork: "holesky",
  networks: {
    hardhat: {},
    local: {
      url: "http://127.0.0.1:8545/",
      accounts: [PRIVATE_KEY_LOCAL],
    },
    holesky: {
      url: API_URL,
      accounts: [PRIVATE_KEY],
    },
  },

};
