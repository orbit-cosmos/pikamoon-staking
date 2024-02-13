require("@nomicfoundation/hardhat-toolbox");
require("solidity-coverage");
require("dotenv").config();
require('solidity-docgen');
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    // LOCAL
    hardhat: {
      forking: {
        // url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
        url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
        blockNumber: 19067936,
      },
      chainId: 31337,
    },
  // sepolia
  "sepolia": {
    accounts: [process.env.PK],
    chainId: 11155111,
    url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
  },
    // ARBITRUM
    "arbitrum-mainnet": {
      accounts: [process.env.PK],
      chainId: 42161,
      url: "https://arb1.arbitrum.io/rpc",
    },
    "arbitrum-sepolia": {
      accounts: [process.env.PK],
      chainId: 421614,
      url: "https://sepolia-rollup.arbitrum.io/rpc",
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      "arbitrum-sepolia": process.env.ETHERSCAN_API,
      "sepolia": process.env.ETHERSCAN_API,
    },
  },
  customChains: [
    {
      network: "arbitrum-sepolia",
      chainId: 421614,
      urls: {
        apiURL: "https://sepolia.arbiscan.io/api",
        browserURL: "https://sepolia.arbiscan.io",
      },
    },
  ],
  sourcify: {
    enabled: true,
  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS) ? true : false
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          // Disable the optimizer when debugging
          // https://hardhat.org/hardhat-network/#solidity-optimizer-support
          optimizer: {
            enabled: true,
            runs: 200,
          },
          evmVersion: "paris",
        },
      },
    ],
  },  docgen: {
    output: 'docs',
    pages: () => 'api.md',
  },
};
