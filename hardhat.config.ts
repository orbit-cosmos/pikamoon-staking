// @ts-nocheck
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "solidity-coverage";
import * as dotenv from "dotenv";
dotenv.config();
import "solidity-docgen";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "@nomiclabs/hardhat-solhint";
import "@nomicfoundation/hardhat-foundry";
const alchemyKey = process.env.ALCHEMY_KEY;
const pk = process.env.PK;

const etherscanApi = process.env.ETHERSCAN_API;

if (!alchemyKey || !pk || !etherscanApi) {
  throw new Error("One or more required environment variables are not defined.");
}


const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    // LOCAL
    hardhat: {
      forking: {
        // url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
        url: `https://eth-mainnet.g.alchemy.com/v2/${alchemyKey}`,
        blockNumber: 19067936,
      },
      chainId: 31337,
    },
    // ethereum mainnet
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${alchemyKey}`,
      chainId: 1,
      accounts: [pk],
    },
    // sepolia
    sepolia: {
      accounts: [pk],
      chainId: 11155111,
      url: `https://eth-sepolia.g.alchemy.com/v2/${alchemyKey}`,
    },
    // ARBITRUM
    "arbitrum-mainnet": {
      accounts: [pk],
      chainId: 42161,
      url: "https://arb1.arbitrum.io/rpc",
    },
    "arbitrum-sepolia": {
      accounts: [pk],
      chainId: 421614,
      url: "https://sepolia-rollup.arbitrum.io/rpc",
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      "mainnet": etherscanApi,
      "sepolia": etherscanApi,
      "arbitrum-mainnet": etherscanApi,
      "arbitrum-sepolia": etherscanApi,
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
    enabled: process.env.REPORT_GAS ? true : false,
  },
  // solidity: {
  //   compilers: [
  //     {
  //       version: "0.8.20",
  //       settings: {
  //         // Disable the optimizer when debugging
  //         // https://hardhat.org/hardhat-network/#solidity-optimizer-support
  //         optimizer: {
  //           enabled: true,
  //           runs: 200,
  //         },
  //         evmVersion: "paris",
  //       },
  //     },
  //   ],
  // },
  solidity: {
    version: "0.8.20", // any version you want
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yulDetails: {
            optimizerSteps: "u",
          },
        },
      },
      evmVersion: "paris",
      metadata: {
        // do not include the metadata hash, since this is machine dependent
        // and we want all generated code to be deterministic
        // https://docs.soliditylang.org/en/v0.7.6/metadata.html
        bytecodeHash: 'none',
      },
    },
  },
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  },
};

export default config;




