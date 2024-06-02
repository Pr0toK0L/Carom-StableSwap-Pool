**First Version:**

This is the BlockChain project about Stable Swap Pool between 3 stablecoins(likely DAI, USDC, USDT)

*Have not included the UI parts, people can interact with contract after deploying it by using address import in RemixIDE:*

1. Import all the contracts to RemixIDE, inluding the 3 tokens address and the custom token address
2. Import the Carom contract address
3. Approve the contract with all 4 tokens
4. Use addMinter with custom token contract to allow the pool to mint token
5. Use initialAddLiquidity function to add liquidity to the pool for the first time
6. Use exchange function to swap between tokens
