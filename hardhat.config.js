require("@nomicfoundation/hardhat-toolbox")
require("hardhat-deploy")
require("dotenv").config()
require("@nomicfoundation/hardhat-ethers")

const PRIVATE_KEY = process.env.PRIVATE_KEY || ""
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || ""
const apiKey = process.env.apiKey || ""

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.20",
    networks: {
        sepolia: {
            chainId: 11155111,
            url: SEPOLIA_RPC_URL,
            accounts: [PRIVATE_KEY],
        },
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    etherscan: {
        apiKey: {
            sepolia: apiKey,
        },
    },
}
