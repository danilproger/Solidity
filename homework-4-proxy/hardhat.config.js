require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("./scripts/deploy");

module.exports = {
    solidity: {
        version: "0.8.28",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        sepolia: {
            url: `https://rpc.ankr.com/eth_sepolia`,
            accounts: [process.env.PRIVATE_KEY_SEPOLIA]
        },
        local: {
            url: `http://127.0.0.1:8545/`,
            accounts: [process.env.PRIVATE_KEY_LOCAL]
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
            sepolia: process.env.ETHERSCAN_API_KEY,
            local: "dummy"
        }
    },
    gasReporter: {
        enabled: true
    }
};