require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200, // Optimize for deployment size and runtime efficiency
      },
    },
  },
  networks: {
    kairos: {
      url: process.env.KAIROS_TESTNET_URL || "",
      chainId: 1001, // Replace with Kairos-specific chainId if needed
      gasPrice: 250000000000, // Set gas price as per network requirements
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    klaytn: {
      url: process.env.KLAYTN_RPC_URL || "RPC_URL", // Use the environment variable or placeholder
      chainId: 1001, // Baobab testnet chainId
      gasPrice: 250000000000, // Adjust gas price if necessary
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: {
      klaytn: "unnecessary", // KlaytnScope doesn't require an API key for verification
    },
    customChains: [
      {
        network: "klaytn",
        chainId: 1001, // Baobab testnet
        urls: {
          apiURL: "https://api-baobab.scope.klaytn.com/api", // Correct Baobab API URL
          browserURL: "https://baobab.scope.klaytn.com", // KlaytnScope Baobab explorer
        },
      },
    ],
  },
};
