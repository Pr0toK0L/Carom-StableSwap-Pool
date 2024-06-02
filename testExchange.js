const { ethers } = require("hardhat")

async function main() {
    // Addresses of deployed contracts
    const caromAddress = "0x199b3E721878672fF4319176a12A7Ac274e5dD60"

    // Get contract instances
    const carom = await ethers.getContractAt("Carom", caromAddress)

    // Get signers
    const [owner] = await ethers.getSigners()

    // Attempt to perform an exchange
    try {
        console.log("Attempting exchange...")
        const tx = await carom
            .connect(owner)
            .exchange(
                0,
                1,
                ethers.parseEther("1000", 6),
                ethers.parseEther("950", 6),
            )
        await tx.wait()
        console.log("Exchange successful")
    } catch (error) {
        console.error("Exchange failed:", error)
    }

    // Log final balances
    const finalBalanceA = await tokenA.balanceOf(owner.address)
    const finalBalanceB = await tokenB.balanceOf(owner.address)
    const finalBalancePoolA = await tokenA.balanceOf(carom.address)
    const finalBalancePoolB = await tokenB.balanceOf(carom.address)

    console.log(
        "Final Balance of Token A:",
        ethers.utils.formatUnits(finalBalanceA, 6),
    )
    console.log(
        "Final Balance of Token B:",
        ethers.utils.formatUnits(finalBalanceB, 6),
    )
    console.log(
        "Final Balance of Token A in Pool:",
        ethers.utils.formatUnits(finalBalancePoolA, 6),
    )
    console.log(
        "Final Balance of Token B in Pool:",
        ethers.utils.formatUnits(finalBalancePoolB, 6),
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
