import { expect } from "chai";
import { Contract, Wallet } from "ethers";
import { ethers } from "hardhat";
import { deployContract, MockProvider, solidity } from 'ethereum-waffle';
import { decryptJsonWalletSync } from "@ethersproject/json-wallets";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { TricastTrio } from "../typechain";

describe("TricastTrio", function () {

  let oracle: Contract;
  let tricastTrio: Contract;
  let wallet0: SignerWithAddress;
  let wallet1: SignerWithAddress;
  let wallet2: SignerWithAddress;
  let wallet3: SignerWithAddress;

  beforeEach(async function () {
    const Oracle = await ethers.getContractFactory("DummyOutcomeProvider");
    oracle = await Oracle.deploy()

    const Tricast = await ethers.getContractFactory("Tricast");
    const TricastTrio = await ethers.getContractFactory("TricastTrio");
    const trio: Contract = await Tricast.deploy();

    await trio.createTrio(oracle.address);
    const tricastInstanceAddress = await trio.allTrios(0);
    
    tricastTrio = new Contract(tricastInstanceAddress, TricastTrio.interface, TricastTrio.signer);

    const wallets = await ethers.getSigners();
    wallet0 = wallets[0];
    wallet1 = wallets[1];
    wallet2 = wallets[2];
    wallet3 = wallets[3];

    (await wallet0.sendTransaction({to: tricastTrio.address, value: 5000})).wait();
    (await wallet1.sendTransaction({to: tricastTrio.address, value: 5000})).wait();
    (await wallet2.sendTransaction({to: tricastTrio.address, value: 5000})).wait();
    (await wallet3.sendTransaction({to: tricastTrio.address, value: 5000})).wait();

    await expect(tricastTrio.connect(wallet2).forBuyLimit(10, 50)).to.be.not.reverted;
    await tricastTrio.connect(wallet3).againstBuyLimit(10, 50);

  });

  it("Transfer funds", async () => {
    (await wallet0.sendTransaction({to: tricastTrio.address, value: 50000})).wait();
    expect(await tricastTrio.connect(wallet3).getDenominatorBalance(wallet0.address)).to.equal(55000);

  });

  it("Place limit buy order", async () => {
    await tricastTrio.connect(wallet0).forBuyLimit(20, 30);
    expect(await tricastTrio.callStatic.getForOrderCount(30)).to.equal(1);

    await tricastTrio.connect(wallet1).againstBuyLimit(20, 30);
    expect(await tricastTrio.callStatic.getAgainstOrderCount(30)).to.equal(1);

  });

  it("Place limit sell order", async () => {
    await tricastTrio.connect(wallet2).forSellLimit(5, 30);
    expect(await tricastTrio.callStatic.getForOrderCount(30)).to.equal(1);

    await tricastTrio.connect(wallet3).againstSellLimit(5, 30);
    expect(await tricastTrio.callStatic.getAgainstOrderCount(30)).to.equal(1);

  });

  it("Market buy exact amount", async () => {
    const balance2 = await tricastTrio.callStatic.getDenominatorBalance(wallet2.address);

    await tricastTrio.connect(wallet2).forSellLimit(5, 30);
    await tricastTrio.connect(wallet1).forBuyMarket(150);

    expect(await tricastTrio.callStatic.getForBalance(wallet1.address)).to.equal(5);
    expect(await tricastTrio.callStatic.getDenominatorBalance(wallet2.address) - balance2).to.equal(150);
  });

  it("Market buy many orders", async () => {
    const balance2 = await tricastTrio.callStatic.getDenominatorBalance(wallet2.address);

    await tricastTrio.connect(wallet2).forSellLimit(1, 30);
    await tricastTrio.connect(wallet2).forSellLimit(1, 30);
    await tricastTrio.connect(wallet2).forSellLimit(1, 30);
    await tricastTrio.connect(wallet2).forSellLimit(1, 30);
    await tricastTrio.connect(wallet2).forSellLimit(1, 30);
    await tricastTrio.connect(wallet1).forBuyMarket(150);

    expect(await tricastTrio.callStatic.getForBalance(wallet1.address)).to.equal(5);
    expect(await tricastTrio.callStatic.getDenominatorBalance(wallet2.address) - balance2).to.equal(150);
  });

  it("Market buy into big limit", async () => {
    const balance2 = await tricastTrio.callStatic.getDenominatorBalance(wallet2.address);

    await tricastTrio.connect(wallet2).forSellLimit(10, 30);
    await tricastTrio.connect(wallet1).forBuyMarket(150);

    expect(await tricastTrio.callStatic.getForBalance(wallet1.address)).to.equal(5);
    expect(await tricastTrio.callStatic.getDenominatorBalance(wallet2.address) - balance2).to.equal(150);
  });

  it("Market sell exact amount", async () => {
    const balance2 = await tricastTrio.callStatic.getDenominatorBalance(wallet2.address);

    await tricastTrio.connect(wallet1).forBuyLimit(5, 30);
    await tricastTrio.connect(wallet2).forSellMarket(5);

    expect(await tricastTrio.callStatic.getForBalance(wallet1.address)).to.equal(5);
    expect(await tricastTrio.callStatic.getDenominatorBalance(wallet2.address) - balance2).to.equal(150);
  });

  it("Market sell many orders", async () => {
    const balance2 = await tricastTrio.callStatic.getDenominatorBalance(wallet2.address);

    await tricastTrio.connect(wallet1).forBuyLimit(1, 30);
    await tricastTrio.connect(wallet1).forBuyLimit(1, 30);
    await tricastTrio.connect(wallet1).forBuyLimit(1, 30);
    await tricastTrio.connect(wallet1).forBuyLimit(1, 30);
    await tricastTrio.connect(wallet1).forBuyLimit(1, 30);

    await tricastTrio.connect(wallet2).forSellMarket(5);

    expect(await tricastTrio.callStatic.getForBalance(wallet1.address)).to.equal(5);
    expect(await tricastTrio.callStatic.getDenominatorBalance(wallet2.address) - balance2).to.equal(150);
  });

  it("Market sell into big limit", async () => {
    const balance2 = await tricastTrio.callStatic.getDenominatorBalance(wallet2.address);

    await tricastTrio.connect(wallet1).forBuyLimit(5, 30);
    await tricastTrio.connect(wallet2).forSellMarket(2);

    expect(await tricastTrio.callStatic.getForBalance(wallet1.address)).to.equal(2);
    expect(await tricastTrio.callStatic.getDenominatorBalance(wallet2.address) - balance2).to.equal(60);
  });

  it("Mint two matching for/against limit orders at middle price", async () => {
    await tricastTrio.connect(wallet0).forBuyLimit(10, 50);
    await tricastTrio.connect(wallet1).againstBuyLimit(10, 50);

    expect(await tricastTrio.callStatic.getAgainstBalance(wallet0.address)).to.equal(0);
    expect(await tricastTrio.callStatic.getForBalance(wallet1.address)).to.equal(0);

    expect(await tricastTrio.callStatic.getForBalance(wallet0.address)).to.equal(10);
    expect(await tricastTrio.callStatic.getAgainstBalance(wallet1.address)).to.equal(10);
  });

  it("Mint two matching for/against limit orders at mirror price", async () => {
    const balance0 = await tricastTrio.callStatic.getDenominatorBalance(wallet0.address);
    const balance1 = await tricastTrio.callStatic.getDenominatorBalance(wallet1.address);
    expect(balance0).to.equal(5000);
    expect(balance1).to.equal(5000);

    await tricastTrio.connect(wallet0).forBuyLimit(10, 30);
    await tricastTrio.connect(wallet1).againstBuyLimit(10, 70);

    expect(await tricastTrio.callStatic.getAgainstBalance(wallet0.address)).to.equal(0);
    expect(await tricastTrio.callStatic.getForBalance(wallet1.address)).to.equal(0);

    expect(await tricastTrio.callStatic.getForBalance(wallet0.address)).to.equal(10);
    expect(await tricastTrio.callStatic.getAgainstBalance(wallet1.address)).to.equal(10);

    expect(balance0 - await tricastTrio.callStatic.getDenominatorBalance(wallet0.address)).to.equal(300);
    expect(balance1 - await tricastTrio.callStatic.getDenominatorBalance(wallet1.address)).to.equal(700);
  });

});