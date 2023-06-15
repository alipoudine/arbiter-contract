import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  console.log(await owner.getBalance())

  const contractFactory = await ethers.getContractFactory("MainArbiter");

  // const contract  = await contractFactory.deploy("0xba12222222228d8ba445958a75a0704d566bf2c8");
  // await contract.deployed()

  // console.log("contract deployed to : ",contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
