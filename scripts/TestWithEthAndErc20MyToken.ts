
import { ethers } from "hardhat";
import { MarketMakingStrategy__factory, MyToken__factory } from "../typechain-types";

async function main() {
  const NO_ERC = '0x0000000000000000000000000000000000000000'

  const signers = await ethers.getSigners();
  const signerAddress= await signers[0].address
  console.log({signerAddress})

  const MyToken = await ethers.getContractFactory("MyToken");
  const myToken = await MyToken.deploy("MyToken", "MTK");

  await myToken.deployed();

  const mmMyTokenContractFactory = new MyToken__factory(signers[0])
  const mmMyTokenContract = mmMyTokenContractFactory.attach(myToken.address)
  await mmMyTokenContract.mint(signerAddress, 1000000000000);

  const ERC_ADDR = await myToken.address
  console.log('ERC Address', ERC_ADDR)
  console.log("Sender ERC before deposit balance", await mmMyTokenContract.balanceOf(signerAddress))

  const MarketMakingStrategy = await ethers.getContractFactory("MarketMakingStrategy");
  const mmStrategy = await MarketMakingStrategy.deploy('ETH', NO_ERC, ERC_ADDR);

  await mmStrategy.deployed();
  await mmMyTokenContract.approve(mmStrategy.address,100000);

  console.log(`Strategy Contract deployed to ${mmStrategy.address}`);
  console.log("Strategy Contract ERC balance before deposit", await mmMyTokenContract.balanceOf(mmStrategy.address))

  const mmStrategyContractFactory = new MarketMakingStrategy__factory(signers[0]);
  const mmStrategyContract = mmStrategyContractFactory.attach(mmStrategy.address);
  console.log("Strategy Contract ETH balance before deposit", await mmStrategyContract.balance())
  let participants = await mmStrategyContract.participants(signerAddress)
  console.log(participants)

  await signers[0].sendTransaction({to: mmStrategyContract.address, value: 100000})
  console.log("Strategy Contract ETH balance after deposit1", await mmStrategyContract.balance())

  console.log(await signers[0].getBalance())
  const deposit = await mmStrategyContract.deposit(100000, mmMyTokenContract.symbol(), {value: 10})
  // console.log(deposit)
  console.log(await signers[0].getBalance())
  console.log("Strategy Contract balance after deposit", await mmMyTokenContract.balanceOf(mmStrategy.address))
  console.log("Strategy Contract ETH balance after deposit2", await mmStrategyContract.balance())

  console.log("Sender ERC after deposit balance", await mmMyTokenContract.balanceOf(signerAddress))

  participants = await mmStrategyContract.participants(signerAddress)
  console.log(participants)

  const start = await mmStrategyContract.start()
  // console.log(start)
  
  const stop = await mmStrategyContract.stop()
  // console.log(stop)

  const claim = await mmStrategyContract.claim()
  // console.log(claim)
  
  


  // const token1Amount = await mmStrategyContract.deposits(token1)
  // console.log(token1Amount)

  console.log("Owner: ", await mmStrategyContract.owner())

  await mmStrategyContract.transferOwnership(signers[1].address)
  console.log("Owner: ", await mmStrategyContract.owner())

  // await mmStrategyContract.address
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
