import { expect } from "chai";
import { Contract, Wallet } from "ethers";
import { ethers } from "hardhat";
import { deployContract, MockProvider, solidity } from 'ethereum-waffle';
import { decryptJsonWalletSync } from "@ethersproject/json-wallets";

// describe("OrderBook", function () {

//   let orderBook: Contract;
//   let wallet0: Wallet;
//   let wallet1: Wallet;

//   beforeEach(async function () {  
//     const OrderBook = await ethers.getContractFactory("OrderBook");
//     orderBook = await OrderBook.deploy()

//     const wallets = new MockProvider().getWallets();
//     wallet0 = wallets[0];
//     wallet1 = wallets[1];
//   });

//   it("Not accepting 0 price limit orders", async () => {
//     await expect(orderBook.limitBuySynth(0, {value: 1000})).to.be.reverted;
//     await expect(orderBook.limitSellSynth(0, 7, {value: 1000})).to.be.reverted;
//   });

//   // it("Same size limit and market orders execute", async () => {
//   //   await wallet0.sendTransaction({to: orderBook.address, value: 100000});
//   //   await expect(orderBook.denominatorBalances(wallet0.address) > 0)
//   // });


// });
