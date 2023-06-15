import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("MainArbiter", function () {
  async function arbLockFixture() {
    const [owner] = await ethers.getSigners();

    
    // let arbitrage = await ethers.getContractAt(
    //   "BalancerFlashLoan",
    //   "0x2F81f273cCE9A0409f834343D1387fD634A2292c",
    //   owner
    // );
    // return { arbitrage };
  }

  // describe("flashLoan", function () {
  //   it("flashloan test", async function () {
  //     const { arbitrage } = await loadFixture(arbLockFixture);

  //     // let transaction = await arbitrage.arbitrage()
  //     // const receipt = await transaction.wait();

  //     // console.log(receipt)

  //     expect(1).to.equal(1);
  //   });
  // });
});
