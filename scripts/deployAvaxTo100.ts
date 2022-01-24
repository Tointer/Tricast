// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { expect } from "chai";
import { providers } from "ethers";
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const provider = ethers.getDefaultProvider();
  const currentTime = (await provider.getBlock(provider.blockNumber)).timestamp;
  const lifetimeSeconds = 10000;

  // We get the contract to deploy
  const Oracle = await ethers.getContractFactory("TokenPriceOracle");
  const oracle = await Oracle.deploy("0x5498BB86BC934c8D34FDA08E81D444153d0D06aD", currentTime+lifetimeSeconds, 100);

  const Tricast = await ethers.getContractFactory("Tricast");
  const TricastTrio = await ethers.getContractFactory("TricastTrio");
  const trio = await Tricast.deploy();

  await trio.createTrio(oracle.address);
  const tricastInstanceAddress = await trio.allTrios(0);

  console.log("OrderBook deployed to:", tricastInstanceAddress);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
