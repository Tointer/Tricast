import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";


describe("OrderBook", function () {

  let orderBook: Contract;

  beforeEach(async function () {
    const OrderQueue = await ethers.getContractFactory("QueueFuns");
    const orderQueue = await OrderQueue.deploy();
  
    const OrderBook = await ethers.getContractFactory("OrderBook", {
      libraries: {
        QueueFuns: orderQueue.address
      }
    });
    orderBook = await OrderBook.deploy()
  });

  it("Not accepting 0 price limit orders", async () => {
    await expect(orderBook.limitBuySynth(0, {value: 1000})).to.be.reverted;
    await expect(orderBook.limitSellSynth(0, 7, {value: 1000})).to.be.reverted;
  });
});
