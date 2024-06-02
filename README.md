**First Version:**

This is the BlockChain project about Stable Swap Pool between 3 stablecoins(likely DAI, USDC, USDT)

1. Have not included the UI parts, people can interact with contract after deploying it by using address import in RemixIDE:
2. Import all the contracts to RemixIDE, inluding the 3 tokens address and the custom token address
3. Import the Carom contract address
4. Approve the contract with all 4 tokens
5. Use addMinter with custom token contract to allow the pool to mint token
6. Use initialAddLiquidity function to add liquidity to the pool for the first time
7. Use exchange function to swap between tokens
