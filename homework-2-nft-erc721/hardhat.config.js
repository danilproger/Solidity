require("@nomicfoundation/hardhat-toolbox");
require("./scripts/deploy");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.28",
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
        apiKey: {
            sepolia: process.env.ETHERSCAN_API_KEY,
        }
    }
};