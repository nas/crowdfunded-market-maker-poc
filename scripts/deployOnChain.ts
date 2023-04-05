import { ethers } from "hardhat";
import { MarketMakingStrategy__factory } from "../typechain-types";
import * as myTokenJson from "./../artifacts/contracts/MyERC20.sol/MyToken.json"
import * as dotenv from "dotenv";
dotenv.config();


async function main() {
  const NO_ERC = '0x0000000000000000000000000000000000000000'
  const args = process.argv;
  const addresses = args.slice(2);

  if (addresses.length < 4)
    throw new Error("Missing parameters for addresses");

  // USAGE:
  // . ts-node --files  scripts/deployOnChain.ts 0x1E250f0ea09857807132067b07038d6c444D1E4A 0x0000000000000000000000000000000000000000 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C ETH
  const owner = addresses[0]
  const token1Address = addresses[1]
  const token2Address = addresses[2]
  const nativeToken = addresses[3]

  // we deploy the contact as us and then transfer the ownership
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey || privateKey?.length <= 0)
    throw new Error("Missing env: Private Key");

  const provider = new ethers.providers.EtherscanProvider(
    process.env.CHAIN_NAME,
    process.env.ETHERSCAN_API_KEY
  );

  const wallet = new ethers.Wallet(privateKey);
  console.log(`Connected to the wallet address ${wallet.address}`);

  const signer = wallet.connect(provider);

  const mmStrategyFactory = new MarketMakingStrategy__factory(signer);

  const mmStrategy = await mmStrategyFactory.deploy(nativeToken, token1Address, token2Address);

  await mmStrategy.deployed();
  const deployTxReceipt = await mmStrategy.deployTransaction.wait();
  console.log(
    `The MM Strategy Contract was deployed at the address ${mmStrategy.address}`
  );

  console.log({ deployTxReceipt });

  console.log("Current Owner: ", await mmStrategy.owner())
  await mmStrategy.transferOwnership(owner);

  // we transfer the contract ownerhship to the strategy creator
  console.log("Ownership Transferred, waiting for confirmations")

  if(token1Address === NO_ERC) {
    console.log("Strategy Contract initial ETH balance for Token1", await mmStrategy.balance())
  } else {
    const token1Contract = new ethers.Contract(token1Address, myTokenJson.abi , signer )
    console.log("Strategy Contract ERC Token1 initial balance", await token1Contract.balanceOf(mmStrategy.address))
  }


  if(token2Address === NO_ERC) {
    console.log("Strategy Contract initial ETH balance for Token2", await mmStrategy.balance())
  } else {
    const token2Contract = new ethers.Contract(token2Address, myTokenJson.abi , signer )
    console.log("Strategy Contract ERC Token2 initial balance", await token2Contract.balanceOf(mmStrategy.address))
  }

  return mmStrategy.address;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

