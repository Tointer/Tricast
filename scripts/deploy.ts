// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { expect } from "chai";
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const OrderQueue = await ethers.getContractFactory("QueueFuns");
  const orderQueue = await OrderQueue.deploy();

  const Greeter = await ethers.getContractFactory("OrderBook", {
    libraries: {
      QueueFuns: orderQueue.address
    }
  });
  const greeter = await Greeter.deploy();

  await greeter.deployed();

  console.log("OrderBook deployed to:", greeter.address);

  //await expect(greeter.limitBuySynth(0, {value: 1000})).to.be.reverted;
  it("Can not buy for 0 price", async () => {
    await expect(greeter.limitBuySynth(0, {value: 1000})).to.be.reverted;
  });

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
