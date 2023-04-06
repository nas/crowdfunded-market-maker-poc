
import { ethers } from "hardhat";
import { MarketMakingStrategy__factory, MyToken__factory } from "../typechain-types";

async function main() {
  const NO_ERC = '0x0000000000000000000000000000000000000000'

  const signers = await ethers.getSigners();
  const signerAddress= await signers[0].address
  const signer2Address= await signers[3].address
  console.log({signerAddress})

  const MyToken = await ethers.getContractFactory("MyToken");
  const myToken = await MyToken.deploy("MyToken", "MTK");
  await myToken.deployed();
  const token1Address = await myToken.address;

  const MyToken2 = await ethers.getContractFactory("MyToken");
  const myToken2 = await MyToken2.deploy("MyToken2", "MTK2");
  await myToken2.deployed();
  const token2Address = await myToken2.address;

  const mmMyTokenContractFactory = new MyToken__factory(signers[0])

  const mmMyTokenContract = mmMyTokenContractFactory.attach(token1Address)
  await mmMyTokenContract.mint(signerAddress, 1000000000000);

  const mmMyTokenContract2 = mmMyTokenContractFactory.attach(token2Address)
  await mmMyTokenContract2.mint(signer2Address, 1000000000000);

  console.log("Sender ERC before deposit balance", await mmMyTokenContract.balanceOf(signerAddress))

  const MarketMakingStrategy = await ethers.getContractFactory("MarketMakingStrategy");
  const mmStrategy = await MarketMakingStrategy.deploy('ETH', token1Address, token2Address);

  await mmStrategy.deployed();

  console.log(`Strategy Contract deployed to ${mmStrategy.address}`);
  console.log("Strategy Contract ERC balance before deposit", await mmMyTokenContract.balanceOf(mmStrategy.address))

  const mmStrategyContractFactory = new MarketMakingStrategy__factory(signers[0]);
  const mmStrategyContract = mmStrategyContractFactory.attach(mmStrategy.address);
  console.log("Strategy Contract ETH balance before deposit", await mmStrategyContract.balance())
  let participants = await mmStrategyContract.participants(signerAddress)
  console.log({participants})


  await mmMyTokenContract2.connect(signers[3]).approve(mmStrategy.address,100000);
  let deposit = await mmStrategyContract.connect(signers[3]).deposit(10099, mmMyTokenContract2.symbol())
  console.log({deposit})

  await mmMyTokenContract.connect(signers[0]).approve(mmStrategy.address,100000);
console.log(await mmMyTokenContract.connect(signers[0]).allowance(signers[0].address, mmStrategy.address))
  deposit = await mmStrategyContract.connect(signers[0]).deposit(109, mmMyTokenContract.symbol())
  console.log({deposit})

  console.log("signer Eth balance after deposit ", await signers[0].getBalance())
  console.log("Strategy Contract deposit balance after deposit", await mmMyTokenContract.balanceOf(mmStrategy.address))
  console.log("Strategy Contract ETH balance after deposit2", await mmStrategyContract.balance())

  console.log("Sender ERC after deposit balance", await mmMyTokenContract.balanceOf(signerAddress))
  console.log("Sender ERC after deposit balance", await mmMyTokenContract2.balanceOf(signers[3].address))

  participants = await mmStrategyContract.participants(signerAddress)
  console.log(participants)
  participants = await mmStrategyContract.participants(signers[3].address)
  console.log(participants)
  console.log(await mmStrategyContract.depositPool(mmMyTokenContract.symbol()))
  console.log(await mmStrategyContract.depositPool(mmMyTokenContract2.symbol()))

  // commenting these out for now, since from here we connect with gridex as is not being handled properly in this script
  // const start = await mmStrategyContract.start() // should successfully start the strategy
  // console.log(start)
  
  // const stop = await mmStrategyContract.stop() // should successfully stop the strategy
  // console.log(stop)

  // const claim = await mmStrategyContract.claim()
  // console.log(claim)
  
  console.log("Owner: ", await mmStrategyContract.owner())

  await mmStrategyContract.transferOwnership(signers[1].address)
  console.log("Owner: ", await mmStrategyContract.owner())

  await mmStrategyContract.address
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
