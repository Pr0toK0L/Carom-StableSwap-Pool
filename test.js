const { ethers } = require("hardhat")
const CaromAbi = require("./abi/Carom.json")
require("dotenv").config()

async function main() {
    const provider = new ethers.JsonRpcProvider("https://rpc-sepolia.rockx.com")
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider)
    const contract = new ethers.Contract(
        "0x199b3E721878672fF4319176a12A7Ac274e5dD60",
        CaromAbi,
        wallet,
    )

    /*
    Convert ether values to Wei
    const amounts = ["0.1", "0.1", "0.1"].map((amount) =>
        ethers.parseEther(amount),
    )

    try {
        const tx = await contract.addLiquidity(amounts, 1, {
            gasLimit: 9000000,
        })
        console.log("Transaction successful:", tx)
    } catch (error) {
        console.error("Transaction failed:", error)
    }
    */
    try {
        console.log("Attempting exchange...")
        const tx = await carom.exchange(
            0,
            1,
            ethers.parseEther("1000", 18),
            ethers.parseEther("950", 18),
        )
        await tx.wait()
        console.log("Exchange successful")
    } catch (error) {
        console.error("Exchange failed:", error)
    }
}

main().catch(console.error)
