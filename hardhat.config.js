require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
  },
  solidity: "0.8.12",
  settings: {
    optimizer: {
      enabled: true,
      runs: 10,
    },
  },
};
