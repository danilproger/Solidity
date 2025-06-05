import {HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "./scripts/deploy";
import "solidity-coverage";

const prodConfig = (): HardhatUserConfig => ({
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    sepolia: {
      url: `https://sepolia.drpc.org`,
      accounts: [process.env.PRIVATE_KEY_SEPOLIA!]
    },
    bscTestnet: {
      url: `https://data-seed-prebsc-1-s1.bnbchain.org:8545`,
      accounts: [process.env.PRIVATE_KEY_BSC!],
    },
    polygonAmoy: {
      url: `https://rpc-amoy.polygon.technology`,
      accounts: [process.env.PRIVATE_KEY_POLYGON!],
    },
    local: {
      url: `http://127.0.0.1:8545/`,
      accounts: [process.env.PRIVATE_KEY_LOCAL!]
    }
  },
  etherscan: {
    customChains: [
      {
        network: "local",
        chainId: 31337,
        urls: {
          apiURL: "http://localhost/api",
          browserURL: "http://localhost",
        },
      },
    ],
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY!,
      bscTestnet: process.env.BSC_API_KEY!,
      polygonAmoy: process.env.POLYGONSCAN_API_KEY!,
      local: "dummy"
    }
  },
  gasReporter: {
    enabled: true
  }
});

const localConfig = (): HardhatUserConfig => ({
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  gasReporter: {
    enabled: true
  }
});

const config = process.env.HARDHAT_ENV === "prod" ? prodConfig() : localConfig();

export default config;
