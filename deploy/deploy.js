// import

const { networks } = require("../hardhat.config")
require("dotenv").config()
const { ethers } = require("ethers")

// main function

// calling of main function

function deployFunc() {
    console.log("Hi")
}

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainID = networks.chainID

    // owner address
    const owner_addr = "0x999268c31D393f4747D6feb43540442bea55942c"

    // DAI, USDC, USDT
    const COINS = [
        "0xFb906D2A2fecDBCfc2DEEDeae7b8e64338E71830",
        "0x959f3a23bE1c40912cE71348162D54e4bf2cf600",
        "0xf6065b2b8EB8799c6B1ba3A4fF0B9cb9a23f6075",
    ]

    // pool_token
    const pool_token = "0x03fC90Ca8eA11c0dcDD128c5C5CAFc71c6408267"

    // FEE
    const FEE = 3000000

    // ADMIN_FEE
    const ADMIN_FEE = 50000000

    const Carom = await deploy("Carom", {
        from: deployer,
        args: [owner_addr, COINS, pool_token, FEE, ADMIN_FEE],
        log: true,
    })
    log(`Carom deployed at ${Carom.address}`)
}

module.exports.tags = ["all", "Carom"]
